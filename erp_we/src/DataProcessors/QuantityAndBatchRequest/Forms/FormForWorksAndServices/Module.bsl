
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	FillingData  = ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm(False);
	FillPropertyValues(FillingData,  Parameters);
	
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.Fill(KeyParameters, FillingData);
	
	DataProcessors.QuantityAndBatchRequest.CheckFilling(Object);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	DiscountOption = "DISCOUNT";
	
	MaxDiscountPercentage   = 0;
	MaxMarkupPercentage  = 0;
	If IsTempStorageURL(Parameters.AddressInTempStorage) Then
		TableStructure = GetFromTempStorage(Parameters.AddressInTempStorage);
		MaxDiscountPercentage  = TableStructure.Restrictions[0].MaximumPercentageForManualDiscount;
		MaxMarkupPercentage = TableStructure.Restrictions[0].MaximumPercentageForManualMarkup;
	EndIf;
	
	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	
	If KeyParameters.SelectGoods And KeyParameters.SelectSupplyOptions Then
		
		AcceptableSecurityOptions = ProvisionInDocumentsClientServer.AcceptableSecurityOptions(
			ItemsType,
			Parameters.AcceptableSeparateActions,
			Parameters.AllowedNonIsolatedActions,
			KeyParameters.LimitSupplyOptions,
			Parameters.SecurityOptionAndFlagSeparately);
			
	EndIf;
	
	ManagingFormElementsDuringCreation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	ClearMessages();
	NumberOfPackagesWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	ClearMessages();
	PackagingWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure SwitchApartOnChange(Item)
	
	SwitchApartWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ActionOnChange(Item)
	
	ActionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ActionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PriceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("Number") Then
		
		Object.PriceKind = Undefined;
		PriceKindPresentation = NStr("vi = '<tùy ý>';
									|ru = '<произвольная>';
									|en = '<custom>'; fa = '<سفارشی>';
									|it = '<arbitraria>';
									|pl = '<dowolny>';
									|tr = '<isteğe bağlı>'");
		
	Else
		
		StandardProcessing = False;
		
		Object.PriceKind = ValueSelected;
		PriceKindPresentation = ValueSelected;
		
		For Each String In Object.TypesOfPrices Do
			If String.PriceKind = ValueSelected Then
				Object.Price = String.Price;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	Object.PriceKind = Undefined;
	PriceKindPresentation = NStr("vi = '<tùy ý>';
								|ru = '<произвольная>';
								|en = '<custom>'; fa = '<سفارشی>';
								|it = '<arbitraria>';
								|pl = '<dowolny>';
								|tr = '<isteğe bağlı>'");
	Object.Price = Number(Text);
	
EndProcedure

&AtClient
Procedure DiscountOptionOnChange(Item)
	
	OptionForGrantingDiscountWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	Cancel = False;
	
	If Parameters.SelectGoods And Object.NumberOfPackages = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền số lượng';
										|ru = 'Не заполнено количество';
										|en = 'Quantity is not filled in'; fa = 'Quantity is not filled in';
										|it = 'Quantità non compilata';
										|pl = 'Nie wypełniono ilości';
										|tr = 'Miktar doldurulmadı'"),,"Object.NumberOfPackages",,Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectedGoods = SelectedGoods();
	
	If Parameters.ItIsForbiddenToSplitStrings Then
		ComplianceOptions = New Map;
		SeriesCount = 0;
		For Each LineProducts_ In SelectedGoods Do
			ComplianceOptions.Insert(LineProducts_.SupplyOption);
			If ValueIsFilled(LineProducts_.Series) Then
				SeriesCount = SeriesCount + 1;
			EndIf;
		EndDo;
		If ComplianceOptions.Count() > 1 Then
			CommonClient.MessageToUser(NStr("vi = 'Đã chọn nhiều phương án đảm bảo, chỉ cho phép chọn một';
											|ru = 'Выбрано несколько вариантов обеспечения, допустимо выбирать только один';
											|en = 'Several supply options have been selected, only one can be selected'; fa = 'Several supply options have been selected, only one can be selected';
											|it = 'Sono state selezionate più opzioni di approvvigionamento, è consentito selezionare solo una';
											|pl = 'Wybrano kilka wariantów zaopatrzenia, dopuszczalne jest wybranie tylko jednego';
											|tr = 'Birkaç tedarik seçeneği seçildi, sadece bir tanesinin seçilmesi kabul edilebilir'"),,,,Cancel);
		EndIf;
		If SeriesCount > 1 And TypeOf(Parameters.Series) <> Type("Array") Then // array in the build order.
			CommonClient.MessageToUser(NStr("vi = 'Đã chọn nhiều sê-ri, chỉ cho phép chọn một';
											|ru = 'Выбрано несколько серий, допустимо выбирать только одну';
											|en = 'Several batches have been selected, only one can be selected'; fa = 'Several batches have been selected, only one can be selected';
											|it = 'Sono state selezionate più serie, è consentito selezionare solo una';
											|pl = 'Wybrano kilka serii, można wybrać tylko jedną';
											|tr = 'Birkaç parti seçildiğinde, yalnızca bir parti seçilmesi kabul edilebilir'"),,,,Cancel);
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If Not KeyParameters.SelectGoods Then
		
		ParametersForSettingShipmentDates = New Structure("TheShipmentDateOfAllLinesIsASingleDate,DateWhenTheNewLinesWereShipped");
		
		If Object.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
				Or Object.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse") Then
			
			ParametersForSettingShipmentDates.TheShipmentDateOfAllLinesIsASingleDate = KeyParameters.TheShipmentDateOfAllLinesIsASingleDate;
			ParametersForSettingShipmentDates.DateWhenTheNewLinesWereShipped          = KeyParameters.DateWhenTheNewLinesWereShipped;
			
		EndIf;
		
		Result = New Structure("SelectedGoods,ParametersForSettingShipmentDates",
		SelectedGoods, ParametersForSettingShipmentDates);
		Close(Result);
		
	Else
		
		Close(New Structure("SelectedGoods", SelectedGoods));
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure NumberOfPackagesWhenChangedOnServer()
	
	WhenChangingNumberOfPackagesOrPackagingOnServer();
	ManagingFormElementsWhenCreatingAndChangingProps(Items.NumberOfPackages);
	
EndProcedure

&AtServer
Procedure PackagingWhenModifiedOnServer()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	DataProcessors.QuantityAndBatchRequest.PackageOnChange(Object, KeyParameters);
	
	WhenChangingNumberOfPackagesOrPackagingOnServer();
	ManagingFormElementsWhenCreatingAndChangingProps(Items.Package);
	
EndProcedure

&AtServer
Procedure WhenChangingNumberOfPackagesOrPackagingOnServer()
	
	OldNumberOfPackages = Object.NumberOfPackages;
	
	PackagingFactor = PackagingFactor(Object.Package, Object.Products);
	Object.Count = Object.NumberOfPackages * PackagingFactor;
	If Object.Count < Object.Goods.Total("Selected") Then
		Object.Count = Object.Goods.Total("Selected");
		Object.NumberOfPackages = Object.Count / PackagingFactor;
	EndIf;
	
	If OldNumberOfPackages < Object.NumberOfPackages Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã nhập số lượng đóng gói ít hơn số lượng đã chọn. Đã chọn %1 %2.';
				|ru = 'Введено количество упаковок меньше, чем уже подобрано. Подобрано %1 %2.';
				|en = 'You have entered fewer packaging units than already picked. Picked: %1 %2.'; fa = 'You have entered fewer packaging units than already picked. Picked: %1 %2.';
				|it = 'Numero di pacchi inserito inferiore a quello già selezionato. Selezionato %1 %2.';
				|pl = 'Wprowadzono ilość opakowań mniej, niż już dobrano. Dobrano %1 %2.';
				|tr = 'Girilen paketleme ünitesi sayısı, halihazırda seçilmiş olan paketleme ünitesi sayısından az. Seçildi %1 %2.'"),
			Object.NumberOfPackages,
			?(ValueIsFilled(Object.Package), Object.Package, UnitOfMeasure));
		Common.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtServer
Procedure SwitchApartWhenChangingOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.SwitchApart);
	If Items.Action.ChoiceList.FindByValue(Object.SupplyOption) = Undefined Then
		Object.SupplyOption = Items.Action.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtServer
Procedure ActionWhenChangingOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.Action);
	
EndProcedure

&AtServer
Procedure OptionForGrantingDiscountWhenChangingOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.DiscountOption);
	
EndProcedure

#EndRegion

#Region WhenCreating

&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	// Setting the form header.
	Text = Undefined;
	
	Text = NStr("vi = 'Nhập số lượng và giá';
				|ru = 'Ввод количества и цены';
				|en = 'Enter quantity and price'; fa = 'ورود مقدار و قیمت';
				|it = 'Inserimento della quantità e del prezzo';
				|pl = 'Wprowadzanie ilości i ceny';
				|tr = 'Miktar ve fiyat girişi'");
	If KeyParameters.HidePrice Then
		Text = NStr("vi = 'Nhập số lượng';
					|ru = 'Ввод количества';
					|en = 'Enter quantity'; fa = 'ورود مقدار';
					|it = 'Inserimento quantità';
					|pl = 'Wprowadzanie ilości';
					|tr = 'Miktar girin'");
	EndIf;
	
	Title = Text;
	
	// Auxiliary details.
	ProductAttributes = New Array();
	ProductAttributes.Add("ItemsType");
	ProductAttributes.Add("PackagingGroup");
	
	ProductAttributes = Common.ObjectAttributesValues(
		Object.Products,
		StrConcat(ProductAttributes,","));
	
	UsePackages = ValueIsFilled(ProductAttributes.PackagingGroup);
		
	// Packaging settings.
	Items.UnitOfMeasure.Visible = Not UsePackages;
	Items.Package.Visible         = UsePackages;
	
	// Setting the visibility of price indicators.
	Items.GroupTypeOfPricePrice.Visible  = Not KeyParameters.HidePrice;
	Items.Price.Enabled             = KeyParameters.EditPriceType;
	
	// Setting the visibility of discounts.
	UseRestrictionsOfManualDiscounts = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
		Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	
	Items.GroupParametersDiscountsMarkups.Visible           = KeyParameters.UseDiscountAdjustmentsInSales
	                                                               And Not KeyParameters.HideManualDiscounts;
	Items.LabelMaximumManualDiscount.Visible        = UseRestrictionsOfManualDiscounts;
	Items.LabelMaximumManualDiscount.Title        = StrTemplate(NStr("vi = '%2 Tối đa chiết khấu: %1 %%';
																	|ru = '%2 Макс. скидка: %1%%';
																	|en = '%2 Max. discount: %1%%'; fa = '%2 Max. discount: %1%%';
																	|it = '%2 Sconto massimo: %1%%';
																	|pl = '%2 Maks. zniżka: %1%%';
																	|tr = '%2 Maksimum indirim: %1%%'"), MaxDiscountPercentage);
	Items.LabelMaximumManualMargin.Visible       = UseRestrictionsOfManualDiscounts;
	Items.LabelMaximumManualMargin.Title       = StrTemplate(NStr("vi = '%2 Tối đa phần thêm: %1 %%';
																	|ru = '%2 Макс. наценка: %1%%';
																	|en = '%2 Max. markup: %1%%'; fa = '%2 Max. markup: %1%%';
																	|it = '%2 Мargine massimo: %1%%';
																	|pl = '%2 Maks. marża: %1%%';
																	|tr = '%2 Maksimum zam: %1%%'"), MaxMarkupPercentage);
	Items.CaptionMaximumDiscountIsNotLimited.Visible  = Not UseRestrictionsOfManualDiscounts;
	Items.CaptionTheMaximumMarginIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts;
	
	// Visibility of the action and the flag "Apart".
	Items.Action.Visible = KeyParameters.SelectGoods
		And KeyParameters.SelectSupplyOptions
		And Not KeyParameters.LimitSupplyOptions;
	Items.SwitchApart.Visible = GetFunctionalOption("UseOrderSupplyWithAssignment")
		And KeyParameters.SelectGoods
		And KeyParameters.SelectSupplyOptions
		And Not KeyParameters.LimitSupplyOptions;
	
	// Setting up elements that should be configured both when creating and when repacking individual elements in the form.
	ManagingFormElementsWhenCreatingAndChangingProps(Undefined);
	
EndProcedure

&AtServer
Procedure ManagingFormElementsWhenCreatingAndChangingProps(Item)
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If Item = Undefined Or Item = Items.Package Then
		
		UnitOfMeasure = Undefined;
		UnitOfMeasure = Object.Package;
		If Not ValueIsFilled(UnitOfMeasure) Then
			UnitOfMeasure = Common.ObjectAttributeValue(Object.Products, "UnitOfMeasure");
		EndIf;
		UnitOfMeasurementCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(UnitOfMeasure, Object.Products);
		
	EndIf;
		
	If Item = Undefined Or Item = Items.Package Then
		
		DataProcessors.QuantityAndBatchRequest.UploadPriceTypesToList(Object, Items.Price.ChoiceList, True);
		
	EndIf;
	
	If Item = Undefined Or Item = Items.Price Then
		
		PriceKindPresentation = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, NStr("vi = '<tùy ý>';
																							|ru = '<произвольная>';
																							|en = '<custom>'; fa = '<سفارشی>';
																							|it = '<arbitraria>';
																							|pl = '<dowolny>';
																							|tr = '<isteğe bağlı>'"));
		
	EndIf;
	
	If Item = Undefined Or Item = Items.Price Or Item = Items.DiscountOption Then
		
		Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = False;
		Items.PercentRateOfManualDiscountMarkup.ChoiceList.Clear();
		
		If DiscountOption = "DISCOUNT" Then
			Items.DiscountOptionsPages.CurrentPage = Items.Discount;
			If MaxDiscountPercentage > 0 Then
				Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
				Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(
					MaxDiscountPercentage,
					Format(MaxDiscountPercentage, "NFD=2"));
			EndIf;
		Else
			Items.DiscountOptionsPages.CurrentPage = Items.Markup;
			If MaxMarkupPercentage > 0 Then
				Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
				Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(
					MaxMarkupPercentage,
					Format(MaxMarkupPercentage, "NFD=2"));
			EndIf;
		EndIf;
		
	EndIf;
	
	// Limiting the list of actions.
	If Item = Undefined
			Or Item = Items.SwitchApart Then
				
				If AcceptableSecurityOptions <> Undefined Then
					
					Items.SwitchApart.Enabled =
						AcceptableSecurityOptions.Separate_.Count() > 0
						And AcceptableSecurityOptions.NonIsolated.Count() > 0;
						
					ItemsList = ?(Object.WithAssignment,
						AcceptableSecurityOptions.Separate_,
						AcceptableSecurityOptions.NonIsolated);
						
					Items.Action.ChoiceList.LoadValues(ItemsList);
					Items.Action.Enabled = Items.Action.ChoiceList.Count() > 1;
						
				EndIf;
				
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Exceeding the maximum discount percentage.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaxDiscountPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DiscountOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "DISCOUNT";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Exceeding the maximum percentage of the margin.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaxMarkupPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DiscountOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "MARKUP";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	
EndProcedure

#EndRegion

&AtServerNoContext
Function PackagingFactor(Package, Products)
	Return Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
EndFunction

&AtServer
Function ProductParameters_1()
	
	ProductParameters_1 = New Structure();
	
	ProductParameters_1.Insert("Products",        Catalogs.Products.EmptyRef());
	ProductParameters_1.Insert("Characteristic",      Catalogs.ItemsCharacteristics.EmptyRef());
	ProductParameters_1.Insert("Package",            Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("Price",                0);
	ProductParameters_1.Insert("PriceKind",             Catalogs.TypesOfPrices.EmptyRef());
	ProductParameters_1.Insert("Warehouse",               Catalogs.Warehouses.EmptyRef());
	ProductParameters_1.Insert("DateOfShipment",        Date('00010101'));
	ProductParameters_1.Insert("SupplyOption",  Enums.SupplyOptions.EmptyRef());
	ProductParameters_1.Insert("WithAssignment",         False);
	ProductParameters_1.Insert("PercentRateOfManualDiscount", 0);
	ProductParameters_1.Insert("NumberOfPackages",  0);
	ProductParameters_1.Insert("Count",          0);
	ProductParameters_1.Insert("BatchesIndicationStatus", 0);
	ProductParameters_1.Insert("Series",               Catalogs.ItemsBatches.EmptyRef());
	
	Return ProductParameters_1;
	
EndFunction

&AtServer
Function SelectedGoods()
	
	SelectedGoods = New Array();
	
	PackagingFactor = PackagingFactor(Object.Package, Object.Products);
	ProductParameters_1 = ProductParameters_1();
	FillPropertyValues(ProductParameters_1, Object,
		"Products,Characteristic,PriceKind,WithAssignment,SupplyOption,NumberOfPackages,Price,Package");
	ProductParameters_1.PercentRateOfManualDiscount = ?(DiscountOption = "DISCOUNT",
		Object.PercentRateOfManualDiscountMarkup,
		-Object.PercentRateOfManualDiscountMarkup);
	ProductParameters_1.Count = Object.NumberOfPackages * PackagingFactor;
	SelectedGoods.Add(ProductParameters_1);
	
	Return SelectedGoods;
	
EndFunction

#EndRegion