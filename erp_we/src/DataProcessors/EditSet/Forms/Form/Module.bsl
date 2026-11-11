#Region Variables

&AtClient
Var CachedValues; // The current item to pass to the waiting handlers.

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	ToUseTermsOfSales         = GetFunctionalOption("ToUseTermsOfSales");
	
	If Not ValueIsFilled(Parameters.AddressInTempStorage) Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	FillPropertyValues(Object, Parameters);
	TSName                             = Parameters.TSName;
	HideSetPrice                = Parameters.HideSetPrice;
	ProhibitPriceEditing          = Parameters.ProhibitPriceEditing;
	ProhibitionOfSetContent = Parameters.ProhibitionOfSetContent;
	HideCommandRemainingQuantityInWarehouses   = Parameters.HideCommandRemainingQuantityInWarehouses;
	DoNotPickReusablePackage     = Parameters.DoNotPickReusablePackage;
	
	HidePriceTypes = Parameters.HidePriceTypes;
	CommonClientServer.SetFormItemProperty(Items, "PriceKind", "Visible", Not HidePriceTypes);
	
	Title = String(Object.ProductsInSet) + ": " + "(" + NStr("vi = 'Soạn tập hợp';
															|ru = 'Редактирование набора';
															|en = 'Edit set'; fa = 'ویرایش مجموعه';
															|it = 'Modifica di un gruppo';
															|pl = 'Edycja zestawu';
															|tr = 'Kümenin düzenlenmesi'") + ")";
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	Components = GetFromTempStorage(Parameters.AddressInTempStorage); // ValueTable
	Object.Components.Load(Components);
	
	// If the type of price is set not in the tabular part but in the header of the document.
	FoundRows = Object.Components.FindRows(New Structure("PriceKind", Catalogs.TypesOfPrices.EmptyRef()));
	If FoundRows.Count() = Object.Components.Count() And ValueIsFilled(Object.PriceKind) Then
		For Each TSRow In Object.Components Do
			TSRow.PriceKind = Object.PriceKind;
		EndDo;
	EndIf;
	
	UnusedAttributes = New Array;
	
	TSComponents = Object.Components.Unload();
	For Each Column In TSComponents.Columns Do
		If Components.Columns.Find(Column.Name) = Undefined
			And UnusedAttributes.Find(Column.Name) = Undefined Then
			UnusedAttributes.Add(Column.Name);
		EndIf;
	EndDo;
	UnusedAttributes.Add("LineNumber");
	
	For Each NameOfUnusedProps In UnusedAttributes Do
		If Items.Find(NameOfUnusedProps) <> Undefined Then
			Items[NameOfUnusedProps].Visible = False;
		EndIf;
	EndDo;
	
	UseDiscountAdjustmentsInSales = True;
	UseDiscountsMarkupsInSales = True;
	
	If UnusedAttributes.Find("PercentRateOfManualDiscount") <> Undefined Then
		Items.GoodsAssignAManualDiscount.Visible = False;
		Items.GoodsCancelManualDiscounts.Visible  = False;
		UseDiscountAdjustmentsInSales = False;
	EndIf;
	
	If UnusedAttributes.Find("PercentRateOfAutomaticDiscountMarkup") <> Undefined Then
		UseDiscountsMarkupsInSales = False;
	EndIf;
	
	If UnusedAttributes.Find("PercentRateOfAutomaticDiscountMarkup") <> Undefined
		And UnusedAttributes.Find("PercentRateOfManualDiscount") <> Undefined Then
		Items.DiscountAmount.Visible = False;
	EndIf;
	
	If UnusedAttributes.Find("Canceled") <> Undefined Then
		Items.GoodsCancelSelectedLines.Visible             = False;
		Items.SumCanceled.Visible                              = False;
	EndIf;
	
	UseReasonsForSalesOrderCancellations = (GetFunctionalOption("UseReasonsForSalesOrderCancellations") And UnusedAttributes.Find("CancellationReason") = Undefined);
	
	Items.AccessoriesGroupCancel.Visible                        = UseReasonsForSalesOrderCancellations And UnusedAttributes.Find("Canceled") = Undefined;
	Items.CanceledReasonsForCancellationNotUsed.Visible = Not UseReasonsForSalesOrderCancellations And UnusedAttributes.Find("Canceled") = Undefined;
	
	ProductConfigurationOptions = SetsServerCall.ProductConfigurationOptions(
		Object.ProductsInSet,
		Object.ItemVariantOfSet);
		
	If Not ValueIsFilled(ProductConfigurationOptions) Then
		Raise NStr("vi = 'Chưa xác định thành phần tập hợp';
					|ru = 'Состав набора не определен';
					|en = 'The set content is not identified'; fa = 'The set content is not identified';
					|it = 'Composizione del set non definita';
					|pl = 'Skład zestawu nie został zdefiniowany';
					|tr = 'Set kapsamı tanımlanmadı'");
	EndIf;
	
	ItemKitConfiguration = ProductConfigurationOptions.ItemKitConfiguration;
	SetPricingOption = ProductConfigurationOptions.SetPricingOption;
	Object.PresentationOptionInPrintForms = ProductConfigurationOptions.PresentationOptionInPrintForms;
	
	If HideSetPrice Then
		Items.GroupPriceAndExplanation.Visible = False;
		Items.InTotal.Visible = False;
	Else
		Items.DecorationPriceIsCalculatedByComponents.Visible = (SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices) And Not ProhibitionOfSetContent;
		Items.DecorationThePriceIsSetPerSet.Visible = (SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		                                               Or SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) And Not ProhibitPriceEditing ;
													   
		Items.TheGroupIsCalculatedByComponents.Visible =    (SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices) Or ProhibitPriceEditing;
		Items.GroupPriceIsSetPerSet.Visible        = Not (SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices) And Not ProhibitPriceEditing;
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	If ValueIsFilled(Parameters.FilterByProductType) And Parameters.FilterByProductType.Count() > 0 Then
		
		FilterByProductType.LoadValues(Parameters.FilterByProductType);
		If FilterByProductType.FindByValue(Enums.ItemsTypes.Set) <> Undefined Then
			FilterByProductType.Delete(FilterByProductType.FindByValue(Enums.ItemsTypes.Set));
		EndIf;
		
		ChoiceParameters = New Array;
		ChoiceParameters.Add(New ChoiceParameter("Filter.ItemsType", FilterByProductType));
		
		Items.Products.ChoiceParameters = New FixedArray(ChoiceParameters);
		
	Else
		
		ItemsTypes = New Array;
		If Not ValueIsFilled(Object.Ref) Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoiceServices") Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		Else
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		EndIf;
		FilterByProductType.LoadValues(ItemsTypes);
		
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	For Each RowOfProduct In Object.Components Do
		
		If RowOfProduct.Products = ProductConfigurationOptions.ProductsOfMainComponent
			And RowOfProduct.Characteristic = ProductConfigurationOptions.MainComponentCharacteristic Then
			RowOfProduct.MainComponent = True;
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.TreatTS(Object.Components, StructureOfActions);
	
	FillInServiceDetailsForProductRange();
	UpdateDuplicateDependentDetails();

	// Calculate the number of sets.
	KitAnalysis(True);
	
	If Parameters.RecalculateAmounts
		And SetPricingOption <> Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		If UsePriceType = 1 Then
			TypeOfKitPriceWhenChangedOnServer();
		Else
			ArbitraryPricePerSetWhenChangingOnServer();
		EndIf;
	Else
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
		RowsToProcess = New Array;
		
		For Each TSRow In Object.Components Do
			If TSRow.Sum > 0 And TSRow.AmountIncludingVAT = 0 Then
				RowsToProcess.Add(TSRow);
			EndIf;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Components);
		
	EndIf;
	
	If UserRightsCached.ThisIsPartner() Then
		Items.GoodsFillThePricesByTermsOfSales.Visible = False;
		Items.GoodsFillInPricesOfSelectedRowsByPriceType.Visible = False;
		Items.GoodsAssignAManualDiscount.Visible = False;
		Items.GoodsCancelManualDiscounts.Visible = False;
		Items.GoodsCancelSelectedLines.Visible = False;
	Else
		If Not ValueIsFilled(Object.Terms) Then
			Items.GoodsFillThePricesByTermsOfSales.Visible = False;
		EndIf;
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Components.CancellationReason");
	NotCheckedAttributeArray.Add("Components.DateOfShipment");
	
	For CurIndex__ = 0 To Object.Components.Count()-1 Do
		
		// The reason for cancellation is mandatory in the lines without the Canceled attribute.
		If GetFunctionalOption("UseReasonsForSalesOrderCancellations")
			And Object.Components[CurIndex__].Canceled
			And Items.CancellationReason.Visible
			And Not ValueIsFilled(Object.Components[CurIndex__].CancellationReason) Then
			
			LineNumber = Object.Components[CurIndex__].LineNumber;
			
			CommonClientServer.MessageToUser(
				StrTemplate(NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ trong dòng %1 của danh sách ""Thành phần chi tiết""';
								|ru = 'Необходимо указать причину отмены в строке %1 списка ""Комплектующие""';
								|en = 'Specify a cancellation reason in line %1 of the Components list'; fa = 'Specify a cancellation reason in line %1 of the Components list';
								|it = 'È necessario indicare il motivo di annullamento nella riga %1 dell''elenco ""Componenti""';
								|pl = 'Należy podać przyczynę anulowania w wierszu %1 listy ""Akcesoria""';
								|tr = '""Bileşenler"" listesinin %1 satırında iptal nedeni belirtilmelidir'"), LineNumber),
				,
				CommonClientServer.PathToTabularSection("Components", LineNumber, "CancellationReason"),
				"Object",
				Cancel);
			
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ComponentsOnStartEdit(Item, NewRow, Copy)
	If Copy Then
		Items.Components.CurrentData.DocumentRowNumber = 0;
	EndIf;
EndProcedure

&AtClient
Procedure ComponentsOnChange(Item)
	
	CalculateOrderTotals(ThisForm);
	
	AttachIdleHandler("KitAnalysisClient", 0.2, True);

EndProcedure

&AtClient
Procedure UsePriceTypeOnChange(Item)
	
	Items.CustomPricePerSet.Enabled = (UsePriceType = 0);
	Items.ThePriceOfTheKit.Enabled           = (UsePriceType = 1);
	
	If UsePriceType = 1 Then
		TypeOfKitPriceWhenChangedOnServer();
	Else
		ArbitraryPricePerSetWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ThePriceOfTheKitOnChange(Item)
	
	TypeOfKitPriceWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CustomPricePerSetOnChange(Item)
	
	ArbitraryPricePerSetWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsComponents

&AtClient
Procedure NumberOfPackagesWhenChanged(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);	
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtClient
Procedure ComponentsProductsWhenChanged(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	CurrentRow.ProductsInSet = Object.ProductsInSet;
	CurrentRow.ItemVariantOfSet = Object.ItemVariantOfSet;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") Then
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Or Not ToUseTermsOfSales Then
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
	Else
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtClient
Procedure TechnicalCharacteristicsWhenChanging(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") Then
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Or Not ToUseTermsOfSales Then
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
	Else
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtClient
Procedure AccessoriesPackagingWhenChanged(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	EndIf;
	
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") Then
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Or Not ToUseTermsOfSales Then
			StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
	Else
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtClient
Procedure ComponentsAfterDeleteRow(Item)
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtServer
Procedure QuantityWhenChangedOnServer()
	
	NumberOfSets = 0;
	CachedValues = Undefined;

	Selection = SetAnalysisResult();
	If Selection.Next() Then
		
		NumberOfSets = Selection.CoefficientMainComponent;
		
	EndIf;
	
	If Object.NumberOfSets > NumberOfSets Then
		
		Query = New Query(
		"SELECT
		|	ConfigurationOptionsForProductRange.Ref.Owner AS ProductsInSet,
		|	ConfigurationOptionsForProductRange.Ref.Characteristic AS ItemVariantOfSet,
		|	CASE
		|		WHEN ConfigurationOptionsForProductRange.Products = ConfigurationOptionsForProductRange.Ref.ProductsOfMainComponent
		|				AND ConfigurationOptionsForProductRange.Characteristic = ConfigurationOptionsForProductRange.Ref.MainComponentCharacteristic
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS MainComponent,
		|	ConfigurationOptionsForProductRange.Products AS Products,
		|	ConfigurationOptionsForProductRange.Products.ItemsType AS ItemsType,
		|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
		|	ConfigurationOptionsForProductRange.Package AS Package,
		|	ConfigurationOptionsForProductRange.NumberOfPackages AS NumberOfPackages,
		|	ConfigurationOptionsForProductRange.Count AS Count
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|WHERE
		|	ConfigurationOptionsForProductRange.Ref = &ProductKitConfigurations");
		
		Query.SetParameter("ProductKitConfigurations", ItemKitConfiguration);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		AvailableProductTypes = FilterByProductType.UnloadValues();
		
		StructureOfStringActionsFound = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfStringActionsFound, Object);
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		If SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
			If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") Then
				If ToUseTermsOfSales And ValueIsFilled(Object.Terms) 
					Or Not ToUseTermsOfSales Then
					StructureOfActions.Insert("FillIn_TermsOfSales", 
						BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(
							Object));
				Else
					StructureOfActions.Insert("FillInSalePrice", 
						BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
				EndIf;
			Else
				If ControlProductRange Then
					StructureOfActions.Insert("FillInSalePriceByProductRange",
						BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
				Else
					StructureOfActions.Insert("FillInSalePrice",
						BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
				EndIf;
			EndIf;
		EndIf;
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));

		RowsToProcess = New Array;
		ProcessedLinesAreNew = New Array;

		While Selection.Next() Do
			
			Filter = New Structure;
			Filter.Insert("Products",   Selection.Products);
			Filter.Insert("Characteristic", Selection.Characteristic);
			Filter.Insert("Package",       Selection.Package);
			Filter.Insert("Canceled",       False);
			FoundRows = Object.Components.FindRows(Filter);
			
			If FoundRows.Count() > 0 Then
				
				CurrentData = FoundRows[0];
				CurrentData.NumberOfPackages = CurrentData.NumberOfPackages + Selection.NumberOfPackages * (Object.NumberOfSets - NumberOfSets);
				
				RowsToProcess.Add(CurrentData);
				
			Else
				
				If AvailableProductTypes.Count() > 0 And AvailableProductTypes.Find(Selection.ItemsType) = Undefined Then
					CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể thêm hàng hóa kiểu %1 vào thành phần của tập hợp này.';
																													|ru = 'Товары с типом %1 не могут быть добавлены в состав данного набора.';
																													|en = 'Goods with type %1 cannot be added to this set content.'; fa = 'Goods with type %1 cannot be added to this set content.';
																													|it = 'Le merci con il tipo %1 non possono essere aggiunte alla composizione del set dato.';
																													|pl = 'Wiersze pozycji z rodzajem %1 nie mogą być dodane do składu tego zestawu.';
																													|tr = '%1 tipine sahip ürünler bu kümeye eklenemez.'"), Selection.ItemsType));
					Continue;
				EndIf;
				
				CurrentRow = Object.Components.Add();
				FillPropertyValues(CurrentRow, Selection);
				
				CurrentRow.NumberOfPackages = Selection.NumberOfPackages * (Object.NumberOfSets - NumberOfSets);
				
				ProcessedLinesAreNew.Add(CurrentRow);
				
			EndIf;
			
		EndDo;

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfStringActionsFound,
			Object.Components,
			CachedValues);

		StructureOfActions.Insert("CheckCharacteristicsByOwner");
		StructureOfActions.Insert("CheckFillPackageByOwner");

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ProcessedLinesAreNew,
			StructureOfActions,
			Object.Components,
			CachedValues);

	EndIf;
		
	If Object.NumberOfSets < NumberOfSets Then
		
		Query = New Query(
		"SELECT
		|	ConfigurationOptionsForProductRange.Ref.Owner AS ProductsInSet,
		|	ConfigurationOptionsForProductRange.Ref.Characteristic AS ItemVariantOfSet,
		|	CASE
		|		WHEN ConfigurationOptionsForProductRange.Products = ConfigurationOptionsForProductRange.Ref.ProductsOfMainComponent
		|				AND ConfigurationOptionsForProductRange.Characteristic = ConfigurationOptionsForProductRange.Ref.MainComponentCharacteristic
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS MainComponent,
		|	ConfigurationOptionsForProductRange.Products AS Products,
		|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
		|	ConfigurationOptionsForProductRange.Package AS Package,
		|	ConfigurationOptionsForProductRange.NumberOfPackages AS NumberOfPackages,
		|	ConfigurationOptionsForProductRange.Count AS Count
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|WHERE
		|	ConfigurationOptionsForProductRange.Ref = &ProductKitConfigurations");
		
		Query.SetParameter("ProductKitConfigurations", ItemKitConfiguration);
		
		Result = Query.Execute();
		Selection = Result.Select();

		RowsToProcess = New Array;

		While Selection.Next() Do
			
			Filter = New Structure;
			Filter.Insert("Products",   Selection.Products);
			Filter.Insert("Characteristic", Selection.Characteristic);
			Filter.Insert("Package",       Selection.Package);
			Filter.Insert("Canceled",       False);
			FoundRows = Object.Components.FindRows(Filter);
			
			ItRemainsToDelete = Selection.NumberOfPackages * (NumberOfSets - Object.NumberOfSets);
			For Each TSRow In FoundRows Do
				
				CurrentData = TSRow;
				If ItRemainsToDelete < CurrentData.NumberOfPackages Then
					CurrentData.NumberOfPackages = CurrentData.NumberOfPackages - ItRemainsToDelete;
					ItRemainsToDelete = 0;
				Else
					ItRemainsToDelete = ItRemainsToDelete - CurrentData.NumberOfPackages;
					CurrentData.NumberOfPackages = 0
				EndIf;
				
				If CurrentData.NumberOfPackages > 0 Then
					RowsToProcess.Add(CurrentData);
				Else
					Object.Components.Delete(CurrentData);
				EndIf;
				
			EndDo;
			
		EndDo;

		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Components,
			CachedValues);

	EndIf;
	
	KitAnalysis();
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	ClearMessages();
	
	QuantityWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ChangePriceViewWhenChanging(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure ComponentsPriceWhenChanged(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure SetPercentageOfManualDiscountWhenChanging(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure MaximumAmountOfManualDiscountWhenChanging(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure TotalAmountWhenChanged(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	PriceFillingStructure = New Structure;
	If UseDiscountsMarkupsInSales Then
		PriceFillingStructure.Insert("UseManualDiscounts");
	EndIf;
	If UseDiscountAdjustmentsInSales Then
		PriceFillingStructure.Insert("UseManualDiscounts");
	EndIf;
	PriceFillingStructure.Insert("QuantityName", "NumberOfPackages");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", PriceFillingStructure);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure TotalAmountOfVATInCaseOfChange(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);

EndProcedure

&AtClient
Procedure MinimumVATRateForChanges(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure ThisIsUndoneByChangeOnServer()
	
	CurrentData = Object.Components.FindByID(Items.Components.CurrentRow);
	
	ForAllRows = False;
	If (SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		Or SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) Then
		ForAllRows = True;
	EndIf;
	
	StringsToProcess = New Array;
	If ForAllRows Then
		For Each TSRow In Object.Components Do
			StringsToProcess.Add(TSRow);
			TSRow.Canceled = CurrentData.Canceled;
			If Not TSRow.Canceled Then
				TSRow.CancellationReason = CurrentData.CancellationReason;
			EndIf;
		EndDo;
	Else
		StringsToProcess.Add(CurrentData);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		StringsToProcess,
		StructureOfActions,
		Object.Components);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure ItWasCanceledWhenTheChangeWasMade(Item)
	
	CurrentRow = Items.Components.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	EndIf;
	
	ThisIsUndoneByChangeOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	FillInPricesByAgreementOnServer();
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)
	
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.CallbackDescription = 
		New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
	PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
	PriceSelectionOptions.UseWhileSellingToCustomers = True;
	PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
	
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		FillInPricesOfSelectedRowsByTypeOfPricesOnServer(PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Components", NStr("vi = 'Thành phần chi tiết';
																											|ru = 'Комплектующие';
																											|en = 'Components'; fa = 'اجزا';
																											|it = 'Componenti';
																											|pl = 'Components';
																											|tr = 'Bileşenler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Components.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateOrderTotals(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Components", NStr("vi = 'Thành phần chi tiết';
																												|ru = 'Комплектующие';
																												|en = 'Components'; fa = 'اجزا';
																												|it = 'Componenti';
																												|pl = 'Components';
																												|tr = 'Bileşenler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure CancelSelectedLines(Command)
	
	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(Object.Components, NStr("vi = 'Thành phần chi tiết';
																							|ru = 'Комплектующие';
																							|en = 'Components'; fa = 'اجزا';
																							|it = 'Componenti';
																							|pl = 'Components';
																							|tr = 'Bileşenler'"), Items.Components.SelectedRows) Then
		Return;
	EndIf;

	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("CancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	UndoSelectedLineSnippet(CancellationReason);
EndProcedure

&AtClient
Procedure CancelSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    UndoSelectedLineSnippet(CancellationReason);

EndProcedure

&AtClient
Procedure UndoSelectedLineSnippet(Val CancellationReason)
    
    Var SelectedRows, StructureOfActions;
    
    StructureOfActions = New Structure;
    StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
    
    SelectedRows = AddToFullSet();
    
    SalesClient.CancelSelectedLines(
    Object.Components,
    SelectedRows,
    CancellationReason,
    StructureOfActions);
    CalculateOrderTotals(ThisForm);
    
    SalesClient.NotifyAboutCancellationOfSelectedLines(CancellationReason);
    
    KitAnalysis();

EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	UntieFromSet = False;
	
	Filter = New Structure("Canceled", False);
	FilterCanceled = New Structure("Canceled", True);
	If Object.NumberOfSets = 0 And Object.Components.FindRows(Filter).Count() > 0 Then
		
		If SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices") Then
			
			QueryText = NStr("vi = 'Không tìm thấy bảng kê chi tiết chính của tập hợp. Bỏ liên kết tất cả thành phần chi tiết với tập hợp?';
							|ru = 'Основная комплектующая набора не найдена. Отвязать все комплектующие от набора?';
							|en = 'The main component of the set is not found. Unlink all components from the set?'; fa = 'The main component of the set is not found. Unlink all components from the set?';
							|it = 'Il componente principale del set non è stato trovato. Scollegare tutte le componenti dal set?';
							|pl = 'Główna część składowa zestawu nie została znaleziona. Odwiązać wszystkie akcesoria z zestawu?';
							|tr = 'Kümenin ana bileşeni bulunamadı. Tüm bileşenleri kümeden ayır?'");
			ButtonsList = New ValueList;
			ButtonsList.Add("UntieFromSet", NStr("vi = 'Bỏ liên kết';
												|ru = 'Отвязать';
												|en = 'Unlink'; fa = 'Unlink';
												|it = 'Scollegare';
												|pl = 'Unlink';
												|tr = 'Ayırmak'"));
			ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
			
			ReturnValue = Undefined;

			
			ShowQueryBox(New CallbackDescription("CompleteEditingCompletion", ThisObject, New Structure("FilterCanceled", FilterCanceled)), QueryText, ButtonsList,,"UntieFromSet");
            Return;
			
		EndIf;
		
	ElsIf Object.NumberOfSets = 0 And Object.Components.Count() = Object.Components.FindRows(FilterCanceled).Count() Then
		// All lines will be moved in the canceled form.
	EndIf;
	
	FinishEditingFragment(UntieFromSet);
EndProcedure

&AtClient
Procedure CompleteEditingCompletion(QuestionResult, AdditionalParameters) Export
    
    FilterCanceled = AdditionalParameters.FilterCanceled;
    
    
    ReturnValue = QuestionResult;
    If ReturnValue = "UntieFromSet" Then
        UntieFromSet = True;
    Else
        Return;
    EndIf;
    
    
    FinishEditingFragment(UntieFromSet);

EndProcedure

&AtClient
Procedure FinishEditingFragment(Val UntieFromSet)
    
    Var CloseParameter;
    
    CloseParameter = New Structure;
    CloseParameter.Insert("AddressInTempStorage", AddressInTempStorage(UntieFromSet));
    CloseParameter.Insert("OwnerForm", ThisForm.FormOwner.UUID);
    CloseParameter.Insert("TSName", TSName);
    
    Notify(
    "Closing_EditingSet",
    CloseParameter,
    ThisForm);
    
    Close();

EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.EditSet.Form.Command.OpenSelection");
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa của bộ';
							|ru = 'Подбор товаров набора';
							|en = 'Pick goods of set'; fa = 'Pick goods of set';
							|it = 'Selezione delle merci del set';
							|pl = 'Dobór towarów zestawu';
							|tr = 'Küme ürünlerin seçimi'");
	FormParameters = New Structure;
	
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", False);
	FormParameters.Insert("HideTheViewPriceColumn",                  False);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     False);
	
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt")
		And TypeOf(Object.Ref) <> Type("DocumentRef.TransferOrder")
		And TypeOf(Object.Ref) <> Type("DocumentRef.InventoryTransfer") Then
		FormParameters.Insert("SelectionModeWithoutAmountParameters", Not SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices"));
		FormParameters.Insert("Currency",          Object.Currency);
		If ToUseTermsOfSales And Object.Terms <> Undefined Then
			FormParameters.Insert("Terms", Object.Terms);
		Else
			FormParameters.Insert("Terms", PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
		EndIf;
		FormParameters.Insert("Partner",         Object.Partner);
		FormParameters.Insert("Date",            Object.Date);
		FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		FormParameters.Insert("VATTaxation", Object.VATTaxation);
		FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	Else
		FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	EndIf;
	
	FormParameters.Insert("Warehouse",                           Object.Warehouse);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", HideCommandRemainingQuantityInWarehouses);
	
	FormParameters.Insert("Document ",               PredefinedValue("Document.SalesOrder.EmptyRef"));
	FormParameters.Insert("Title",               HeaderParameter_);
	FormParameters.Insert("FilterByProductType", FilterByProductType.UnloadValues());
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Components",
		"Products,Characteristic,Count");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateDuplicateDependentDetails()
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Components, DependentDetails());
	
EndProcedure

&AtServer
Function SetAnalysisResult(ActiveOnly = True)
	
	Query = New Query(
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Count AS Count
	|INTO SetComposition
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConfigurationOptionsForProductRange.Products AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	CASE WHEN ConfigurationOptionsForProductRange.Ref.ProductsOfMainComponent = ConfigurationOptionsForProductRange.Products
	|		AND ConfigurationOptionsForProductRange.Ref.MainComponentCharacteristic = ConfigurationOptionsForProductRange.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|INTO Table
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref = &ProductKitConfigurations
	|
	|GROUP BY
	|	CASE WHEN ConfigurationOptionsForProductRange.Ref.ProductsOfMainComponent = ConfigurationOptionsForProductRange.Products
	|		AND ConfigurationOptionsForProductRange.Ref.MainComponentCharacteristic = ConfigurationOptionsForProductRange.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	FALSE,
	|	0,
	|	Table.Count
	|FROM
	|	SetComposition AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO Result
	|FROM
	|	Table AS Table
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS ThereAreAdditionalProducts,
	|	ISNULL(CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1, 0) AS CoefficientMainComponent,
	|	MAX(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) AS CoefficientMaximum,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumRatio
	|FROM
	|	Result AS Result
	|");
	
	Query.SetParameter("ProductKitConfigurations", ItemKitConfiguration);
	
	If ActiveOnly Then
		Filter = New Structure;
		Filter.Insert("Canceled", False);
		Components = Object.Components.Unload(Filter);
	Else
		Components = Object.Components.Unload();
	EndIf;
	Components.GroupBy("Products, Characteristic", "Count");
	Query.SetParameter("Table", Components);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Return Selection;
	
EndFunction

&AtServer
Procedure KitAnalysis(PriceChange = False)
	
	RightSelectionOfMultiTurnPackaging        = AccessRight("View", Metadata.DataProcessors.SelectReusablePackage);
	PriceIsCalculatedFromPricesOfComponents = (SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices);
	
	Items.Components.ChangeRowSet                    = PriceIsCalculatedFromPricesOfComponents And Not ProhibitionOfSetContent;
	Items.Products.ReadOnly             = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.Characteristic.ReadOnly           = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.GroupBasketPackagingUnitOfMeasurement.ReadOnly = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.NumberOfPackages.ReadOnly       = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.PriceKind.ReadOnly                  = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.Price.ReadOnly                     = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.Sum.ReadOnly                    = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.VATAmount.ReadOnly                 = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.VATRate.ReadOnly                = Not PriceIsCalculatedFromPricesOfComponents Or ProhibitionOfSetContent;
	Items.ComponentsAddReusablePackage.Visible  = PriceIsCalculatedFromPricesOfComponents
	                                                                And Not ProhibitionOfSetContent
	                                                                And RightSelectionOfMultiTurnPackaging
	                                                                And Not DoNotPickReusablePackage;
	
	Items.GroupProductsPrices.Visible             = PriceIsCalculatedFromPricesOfComponents And Not ProhibitPriceEditing;
	Items.ComponentsOpenSelection.Visible   = PriceIsCalculatedFromPricesOfComponents And Not ProhibitionOfSetContent;
	
	StandardSet = False;
	Selection = SetAnalysisResult();
	If Selection.Next() Then
		
		StandardSet = (Selection.MinimumRatio = Selection.CoefficientMaximum) And Not Selection.ThereAreAdditionalProducts;
		
		Object.NumberOfSets = Selection.CoefficientMainComponent;
		
		If Not StandardSet Then
			Items.TheGroupSetChanged.CurrentPage = Items.TheGroupSetChanged.ChildItems.PageIsDisplayed;
		Else
			Items.TheGroupSetChanged.CurrentPage = Items.TheGroupSetChanged.ChildItems.PageIsNotDisplayed;
		EndIf;
		
	EndIf;
	
	If PriceChange Or PriceIsCalculatedFromPricesOfComponents Then
		
		If SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
		 Or SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices Then
			
			NumberOfCanceledLines = 0;
			
			PricePerSet = 0;
			ThePriceOfTheKit = Undefined;
			UsePriceType = 1;
			For Each RowOfProduct In Object.Components Do
				
				If RowOfProduct.Canceled Then
					NumberOfCanceledLines = NumberOfCanceledLines + 1;
				EndIf;
				
				If ThePriceOfTheKit = Undefined Then
					ThePriceOfTheKit = RowOfProduct.PriceKind;
					If Not ValueIsFilled(ThePriceOfTheKit) Then
						UsePriceType = 0;
					EndIf;
				EndIf;
				If UsePriceType = 1 And ThePriceOfTheKit <> RowOfProduct.PriceKind Then
					UsePriceType = 0;
				EndIf;
				
				PricePerSet = PricePerSet + RowOfProduct.Sum + RowOfProduct.ManualDiscount + RowOfProduct.DiscountMarkupAmount;
				
			EndDo;
			
			If NumberOfCanceledLines = Object.Components.Count() Then
				AnalysisOfCanceledSet = SetAnalysisResult(False);
				If AnalysisOfCanceledSet.Next() And AnalysisOfCanceledSet.CoefficientMainComponent <> 0 Then
					Object.Price = PricePerSet / AnalysisOfCanceledSet.CoefficientMainComponent;
				Else
					Object.Price = 0;
				EndIf;
			Else
				If Object.NumberOfSets <> 0 Then
					Object.Price = PricePerSet / Object.NumberOfSets;
				Else
					Object.Price = 0;
				EndIf;
			EndIf;
			
			If UsePriceType = 1 Then
				Object.PriceKind = ThePriceOfTheKit;
			EndIf;
			
			Items.CustomPricePerSet.Enabled = (UsePriceType = 0);
			Items.ThePriceOfTheKit.Enabled           = (UsePriceType = 1);
			
		ElsIf SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
			
			NumberOfCanceledLines = 0;
			
			PricePerSet = 0;
			PricePerSetWithCanceledLines = 0;
			For Each RowOfProduct In Object.Components Do
				
				If RowOfProduct.Canceled Then
					NumberOfCanceledLines = NumberOfCanceledLines + 1;
				EndIf;
				
				PricePerSetWithCanceledLines = PricePerSetWithCanceledLines + RowOfProduct.Sum + RowOfProduct.ManualDiscount + RowOfProduct.DiscountMarkupAmount;
				
				If RowOfProduct.Canceled Then
					Continue;
				EndIf;
				
				PricePerSet = PricePerSet + RowOfProduct.Sum + RowOfProduct.ManualDiscount + RowOfProduct.DiscountMarkupAmount;
				
			EndDo;
			
			If NumberOfCanceledLines = Object.Components.Count() Then
				AnalysisOfCanceledSet = SetAnalysisResult(False);
				If AnalysisOfCanceledSet.Next() And AnalysisOfCanceledSet.CoefficientMainComponent <> 0 Then
					Object.Price = PricePerSetWithCanceledLines / AnalysisOfCanceledSet.CoefficientMainComponent;
				Else
					Object.Price = PricePerSetWithCanceledLines;
				EndIf;
			Else
				If Object.NumberOfSets <> 0 Then
					Object.Price = PricePerSet / Object.NumberOfSets;
				Else
					Object.Price = PricePerSet;
				EndIf;
			EndIf;
			
		EndIf;
		
	Else
		If UsePriceType = 1 Then
			TypeOfKitPriceWhenChangedOnServer();
		Else
			ArbitraryPricePerSetWhenChangingOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Components,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateOrderTotals(Form)
	
	// Filling in the totals according to the "Products" table.
	
	CollectionProducts = Form.Object.Components;

	Form.AmountOrdered     = CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled");
	Form.AmountNDSOrdered  = CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled");
	Form.AutoDiscountAmount   = CollectionProducts.Total("DiscountMarkupAmount") - CollectionProducts.Total("DiscountMarkupAmountCanceled");
	Form.ManualDiscount = CollectionProducts.Total("ManualDiscount") - CollectionProducts.Total("ManualDiscountCanceled");
	Form.DiscountAmount       = Form.AutoDiscountAmount + Form.ManualDiscount;
	Form.SumCanceled     = CollectionProducts.Total("AmountIncludingVATCanceled");
	
	If CollectionProducts.Total("AmountIncludingVATCanceled") = CollectionProducts.Total("AmountIncludingVAT") Then
		Form.AllLinesAreCanceled = True;
	Else
		Form.AllLinesAreCanceled = False;
	EndIf;
	
	AmountOrdered = CollectionProducts.Total("Sum") - CollectionProducts.Total("SumCanceled");
	
	If AmountOrdered > 0 Then
		Form.AutoDiscountPercentage   = Form.AutoDiscountAmount * 100 / (AmountOrdered + Form.DiscountAmount);
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / (AmountOrdered + Form.DiscountAmount);
		Form.DiscountPercentage       = Form.AutoDiscountPercentage + Form.PercentRateOfManualDiscount;
	ElsIf Form.DiscountAmount > 0 Then
		Form.AutoDiscountPercentage   = Form.AutoDiscountAmount * 100 / Form.DiscountAmount;
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / Form.DiscountAmount;
		Form.DiscountPercentage       = 100;
	Else
		Form.AutoDiscountPercentage   = 0;
		Form.PercentRateOfManualDiscount = 0;
		Form.DiscountPercentage       = 0;
	EndIf;
	
	// Selecting the VAT display page.
	If Form.Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT")
		Or Form.Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII") Then
		
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		
	Else
		
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateComponentPrices(PriceKind, Price)
	
	Components = Object.Components.Unload();
	UseFilter1 = False;
	Filter = New Structure;
	If Components.Columns.Find("Canceled") <> Undefined Then
		UseFilter1 = True;
		Filter.Insert("Canceled", False);
	EndIf;
	
	FillParameters = New Structure; // Fill-in parameters.
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("PopulationFields", "Price");
	
	If UseFilter1 Then
		CoefficientsOfProportionalityOfCalculationOfPricesOfSets = SetsServer.DistributionCoefficients(
			Object.Components.Unload(Filter),
			FillParameters);
	Else
		CoefficientsOfProportionalityOfCalculationOfPricesOfSets = SetsServer.DistributionCoefficients(
			Object.Components.Unload(),
			FillParameters);
	EndIf;
	
	TotalCost = 0;
	AmountForAllocation = Price * Object.NumberOfSets;
	PriceIsFilledIn = False;
	
	ServiceTS = New ValueTable;
	ServiceTS.Columns.Add("TSRow");
	ServiceTS.Columns.Add("Count");
	ServiceTS.Columns.Add("Cost");
	For Each CurrentRow In Object.Components Do
		
		If CurrentRow.Canceled Then
			Continue;
		EndIf;
		
		Cost = CoefficientsOfProportionalityOfCalculationOfPricesOfSets.Find(CurrentRow.LineNumber, "LineNumber").Price;
		Count = ?(TMCommonUseClientServer.HasObjectAttribute(CurrentRow, "NumberOfPackages"), CurrentRow.NumberOfPackages, CurrentRow.Count);
		
		NewRow = ServiceTS.Add();
		NewRow.TSRow = CurrentRow;
		NewRow.Cost = Cost;
		NewRow.Count = Count;
		
		TotalCost = TotalCost + Cost;
		
		If Cost <> 0 Then
			PriceIsFilledIn = True;
		EndIf;
		
	EndDo;
	ServiceTS.Sort("Count DESC");
	
	LineNumber = 0;
	RowsCount = ServiceTS.Count();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ErrorsByLines = New Map();
	RowsToProcess = New Array();
	
	For Each ServiceTSString In ServiceTS Do
		
		LineNumber = LineNumber + 1;
		
		CurrentRow = ServiceTSString.TSRow;
		Cost = ServiceTSString.Cost;
		Count = ServiceTSString.Count;
		
		CurrentRow.PriceKind = PriceKind;
		If Count <> 0 And TotalCost <> 0 Then
			CurrentRow.Price = Round(((Cost / TotalCost) * AmountForAllocation) / Count, 2);
		Else
			CurrentRow.Price = 0;
		EndIf;
		
		TotalCost = TotalCost - Cost;
		AmountForAllocation = AmountForAllocation - CurrentRow.Price * Count;
		
		Error_ = 0;
		If LineNumber = RowsCount And PriceIsFilledIn Then
			Error_ = AmountForAllocation;
		EndIf;
		
		ErrorsByLines.Insert(CurrentRow, Error_);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountRoundingError",
		New Structure("ErrorsByLines", ErrorsByLines));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Components,
		CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure ArbitraryPricePerSetWhenChangingOnServer()
	
	CalculateComponentPrices(Catalogs.TypesOfPrices.EmptyRef(), Object.Price);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure FillInPricesOfSelectedRowsByTypeOfPricesOnServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Components.SelectedRows Do
		RowsArray.Add(Object.Components.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Components,
		RowsArray, // Array of rows or selection structure.
		FillParameters,
		StructureOfActions);
		
	CalculateOrderTotals(ThisForm);

EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName				 = "Components";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.OnlyForActiveRows			 = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Components", AmountOfDiscountMarkUp, DiscountParameters);
	UpdateDuplicateDependentDetails();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Components.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Price.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Sum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "Characteristic",
																		     "Object.Components.ItemVariantsAreUsed");

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm, 
									                     "PriceKind", 
                                                         "Object.Components.PriceKind");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LineNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Products.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Characteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NumberOfPackages.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Package.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceKind.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Price.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Sum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VATAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AmountIncludingVAT.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsSKU.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsTypeOfProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CancellationReason.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.CancellationReason");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManualDiscount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkNegatives", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CancellationReason.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Components.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm, 
													"VATRate", 
													"VATAmount", 
													"AmountIncludingVAT");
	
	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "AmountIncludingVAT");
	
EndProcedure

&AtServer
Function AddressInTempStorage(UntieFromSet)
	
	Data = New Structure;
	Data.Insert("ProductsInSet",   Object.ProductsInSet);
	Data.Insert("ItemVariantOfSet", Object.ItemVariantOfSet);
	Data.Insert("DocumentSalesOfGoodsAndServices",   Object.DocumentSalesOfGoodsAndServices);
	Data.Insert("SalesOrder", Object.SalesOrder);
	Data.Insert("Components",        Object.Components.Unload());
	Data.Insert("TSName",                TSName);
	Data.Insert("UntieFromSet",     UntieFromSet);
	
	Return PutToTempStorage(Data, UUID);
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"Canceled",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount");
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClient
Procedure KitAnalysisClient()
	
	KitAnalysis();
	
EndProcedure

&AtServer
Function AddToFullSet()
	
	TabularSection = Object.Components;
	SelectedRows = Items.Components.SelectedRows;
	
	RowsArray = New Array;
	For Each CurRow In SelectedRows Do
		TableRow = TabularSection.FindByID(CurRow);
		RowsArray.Add(TableRow);
	EndDo;
	
	SetsServerCall.AddToFullSet(TabularSection, RowsArray);
	
	Result = New Array;
	For Each TSRow In RowsArray Do
		Result.Add(TSRow.GetID());
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Components", True, True);
	UpdateDuplicateDependentDetails();
	
EndProcedure

&AtServer
Procedure TypeOfKitPriceWhenChangedOnServer()
	
	ProductParameters_ = EnterprisePricesFillingServer.NewSelectionParametersGetPriceBySelection();
	ProductParameters_.Insert("Products", Object.ProductsInSet);
	ProductParameters_.Insert("Characteristic", Object.ItemVariantOfSet);
	ProductParameters_.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_.Insert("Currency", Object.Currency);
	ProductParameters_.Insert("Date", Object.Date);
	ProductParameters_.Insert("PriceKind", Object.PriceKind);
	Price = EnterprisePricesFillingServer.GetPriceBySelection(ProductParameters_);
	
	CalculateComponentPrices(Object.PriceKind, Price);
	
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure FillInPricesByAgreementOnServer()
	
	If Not ToUseTermsOfSales Or Object.Terms = Undefined Then
		Return;
	EndIf;
	
	RowsArray = New Array;
	For Each String In Items.Components.SelectedRows Do
		RowsArray.Add(Object.Components.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Components,
		RowsArray, // Array of rows or selection structure.
		FillParameters,
		StructureOfActions);

	CalculateOrderTotals(ThisForm);

EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceipt") Then
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Components.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, 
			"Products, Characteristic, Package, PriceKind, Price, NumberOfPackages, PercentRateOfManualDiscount, ManualDiscount");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Components);
	
	FillInServiceDetailsForProductRange();
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	ActionStructureModifiedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);;
	
	If TypeOf(Object.Ref) <> Type("DocumentRef.CashRegisterReceipt") Then
		If ValueIsFilled(Object.Terms) Then
			StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
	Else
		If ControlProductRange Then
			StructureOfActionsAddedLines.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Components",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	FillInServiceDetailsForProductRange();
	
	CalculateOrderTotals(ThisForm);
	
	KitAnalysis();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	Items.DecorationPriceIsCalculatedAccordingToComponentsTypeOfPriceIsNotSet.Visible = 
		(SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices)
			And Not ValueIsFilled(Object.PriceKind) And ValueIsFilled(Object.Price);
	
EndProcedure

#EndRegion
