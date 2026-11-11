
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	FormCode = "Processing_SupplierPriceList_ConfigurationForm";
	
	// For the efficiency of procedures for the selection of goods.
	UseFilters = True;
	FlagOfOpeningAForm = True;
	
	UsePriceGroups              = GetFunctionalOption("UsePriceGroups");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	UsePartnersProducts      = GetFunctionalOption("UsePartnersProducts");
	
	StructureOfData = GetFromTempStorage(Parameters.PriceListSettings);  // See SettingPricesClientServer.NewFormSettingsStructure
	SettingPricesServer.LoadDefaultSelectionSettings(ThisForm);
	SettingsComposerFilter.LoadSettings(StructureOfData.ComposerSettings);
	
	Object.Partner = StructureOfData.Partner;
	If Parameters.BlockTheChangeOfFilterBySupplier Then
		Items.Partner.ReadOnly = Parameters.BlockTheChangeOfFilterBySupplier;
	EndIf;
	
	InitializePartnerProductHierarchyTree();
	InitializeProductHierarchyTree();
	
	SettingPricesServer.InitializeSelectedPrices(ThisForm);
	For Each TSRow In StructureOfData.SelectedPrices Do
		FillPropertyValues(SettingPricesClientServer.FindPriceTypeString(SelectedPrices, TSRow[0]), TSRow);
	EndDo;
	
	Date = StructureOfData.Date;
	
	ProductKind = StructureOfData.ProductKind;
	SelectGoodsServer.FillInProductSelectionTree(ThisForm);

	FilterParametersTable.Load(StructureOfData.FilterParametersTable);
	
	SimplifiedSetting = ConvertAdvancedSettingToSimplifiedOne(ThisForm);
	FillPropertyValues(ThisForm, SimplifiedSetting);
	
	Items.NavigationOption.ChoiceList.Clear();
	If UsePartnersProducts Then
		Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.ByVendorHierarchy, NStr("vi = 'Theo phân nhánh';
																										|ru = 'По иерархии';
																										|en = 'By hierarchy'; fa = 'بر اساس سلسله‌مراتب';
																										|it = 'Per gerarchia';
																										|pl = 'Wg hierarchii';
																										|tr = 'Hiyerarşiye göre'"));
		If ValueIsFilled(SimplifiedSetting.Products) Then
			Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.ByVendorPartNumbers, NStr("vi = 'Theo mặt hàng nhà cung cấp';
																											|ru = 'По номенклатуре поставщика';
																											|en = 'By vendor part numbers'; fa = 'By vendor part numbers';
																											|it = 'Per articolo del fornitore';
																											|pl = 'Wg  nomenklatury dostawcy';
																											|tr = 'Tedarikçi parça numaralarına göre'"));
			Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives, NStr("vi = 'Theo mặt hàng';
																													|ru = 'По номенклатуре';
																													|en = 'By items'; fa = 'بر اساس اقلام';
																													|it = 'Per articolo';
																													|pl = 'Wg produktów';
																													|tr = 'Öğeye göre'"));
		Else
			Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.ByVendorPartNumbers, NStr("vi = 'Theo mặt hàng';
																											|ru = 'По номенклатуре';
																											|en = 'By items'; fa = 'بر اساس اقلام';
																											|it = 'Per articolo';
																											|pl = 'Wg produktów';
																											|tr = 'Öğeye göre'"));
		EndIf;
	Else
		Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.ByHierarchy, NStr("vi = 'Theo phân nhánh';
																								|ru = 'По иерархии';
																								|en = 'By hierarchy'; fa = 'بر اساس سلسله‌مراتب';
																								|it = 'Per gerarchia';
																								|pl = 'Wg hierarchii';
																								|tr = 'Hiyerarşiye göre'"));
		Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.ByProperties, NStr("vi = 'Theo thuộc tính';
																								|ru = 'По свойствам';
																								|en = 'By properties'; fa = 'بر اساس ویژگی‌ها';
																								|it = 'Per proprietà';
																								|pl = 'Wg właściwości';
																								|tr = 'Özelliğe göre'"));
		Items.NavigationOption.ChoiceList.Add(Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives, NStr("vi = 'Theo mặt hàng';
																												|ru = 'По номенклатуре';
																												|en = 'By items'; fa = 'بر اساس اقلام';
																												|it = 'Per articolo';
																												|pl = 'Wg produktów';
																												|tr = 'Öğeye göre'"));
	EndIf;
	
	NavigationOption = StructureOfData.NavigationOption;
	If Not ValueIsFilled(NavigationOption) Then
		If UsePartnersProducts Then
			NavigationOption = Enums.ItemFormNavigationOptions.ByVendorHierarchy;
		Else
			NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy;
		EndIf;
	EndIf;
	If Items.NavigationOption.ChoiceList.FindByValue(NavigationOption) = Undefined Then
		NavigationOption = Items.NavigationOption.ChoiceList[0].Value;
	EndIf;
	NavigationOptionWhenChangingOnServer();
	
	AutoTagBlankContent(ThisForm);
	
	If ValueIsFilled(Parameters.GoodsWithSimilarProperties) Then
		
		FilterBySimilarProperties(ThisForm, Parameters.GoodsWithSimilarProperties.Products);
		SettingKind = "Basic";
		CustomizeForm(ThisForm);
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.Filters;
		
	Else
		
		If SimplifiedSetting.PartnerProducts <> Undefined Then
			NavigationOption = Enums.ItemFormNavigationOptions.ByVendorPartNumbers;
			NavigationOptionWhenChangingOnServer();
			
			For Each Item In SimplifiedSetting.PartnerProducts Do
				NewRow = PartnerSNomenclatureTable.Add();
				NewRow.Ref = Item;
			EndDo;
			
		EndIf;
		If SimplifiedSetting.Products <> Undefined Then
			NavigationOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives;
			NavigationOptionWhenChangingOnServer();
			ItemList.LoadValues(SimplifiedSetting.Products);
		EndIf;
		
		If SimplifiedSetting.SettingsWillBeLost And StructureOfData.SettingKind <> "Basic" Then
			SettingKind = "Advanced";
		Else
			SettingKind = "Basic";
		EndIf;
		
		If UsePartnersProducts Then
			SetProductGroupsRecursively(SimplifiedSetting.PartnerProductGroups, TheHierarchyTreeOfItemPartner.GetItems());
		Else
			SetProductGroupsRecursively(SimplifiedSetting.ProductGroups, ProductsHierarchyTree.GetItems());
		EndIf;
		
		CustomizeForm(ThisForm);
		
	EndIf;
	
	Items.TypesOfPrices.Visible = Not Parameters.SelectionOnly;
	If Parameters.SelectionOnly Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorPriceTypes"
		And Parameter.Partner = Object.Partner Then
		
		ReReadVendorPriceTypesOnServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingKindOnChange(Item)
	
	SimplifiedSetting = (ThisForm.SettingKind = "Basic");
	If SimplifiedSetting Then
		
		SimplifiedSetting = ConvertAdvancedSettingToSimplifiedOne(ThisForm);
		If SimplifiedSetting.SettingsWillBeLost Then
			
			QueryText = NStr("vi = 'Có thể mất nhiều tùy chỉnh. Chuyển sang tùy chỉnh đơn giản?';
							|ru = 'Некоторые настройки могут быть потеряны. Перейти к упрощенным настройкам?';
							|en = 'Some settings may be lost. Go to simple settings?'; fa = 'Some settings may be lost. Go to simple settings?';
							|it = 'Alcune impostazioni potrebbero andare perse. Passare alle impostazioni semplificate?';
							|pl = 'Niektóre ustawienia mogą zostać utracone. Przejść do uproszczonych ustawień?';
							|tr = 'Bazı ayarlar kaybolabilir. Basitleştirilmiş ayarlara geçilsin mi?'");
			
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("vi = 'Chuyển đến';
										|ru = 'Перейти';
										|en = 'Navigate'; fa = 'پیمایش';
										|it = 'Vai a';
										|pl = 'Navigate';
										|tr = 'Git'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
			
			ShowQueryBox(
				New CallbackDescription("SettingsWillBeLostCompletion", ThisObject, New Structure("SimplifiedSetting", SimplifiedSetting)),
				QueryText,
				Buttons);
				
			Return;
			
		EndIf;
		
		ViewSettingsWhenChangingFragment(SimplifiedSetting);
		
		AutoTagBlankContent(ThisForm);
		
	Else
		
		ConvertSimplifiedSetupToAdvancedOne(ThisForm);
		CustomizeForm(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceFromOnChange(Item)
	AutoTagBlankContent(ThisForm);
EndProcedure

&AtClient
Procedure PriceUpToOnChange(Item)
	AutoTagBlankContent(ThisForm);
EndProcedure

&AtClient
Procedure NavigationOptionOnChange(Item)
	
	NavigationOptionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductKindOnChangeServer();
	
EndProcedure

&AtClient
Procedure TypeOfPriceSelectionOnChange(Item)
	AutoTagBlankContent(ThisForm);
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedPrices

&AtClient
Procedure SelectedPricesSelected_5OnChange(Item)
	
	CurrentData = Items.SelectedPrices.CurrentData;
	SelectedPricesWereChanged = True;
	If CurrentData.ProhibitedPriceType Then
		CurrentData.Selected_5 = False;
		AttachIdleHandler("InformAboutImpossibilityOfSelection", 0.2, True);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedPricesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	Filter = New Structure;
	Filter.Insert("Owner", Object.Partner);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", Filter);
	
	OpenForm("Catalog.VendorPriceTypes.Form.ItemForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SelectedPricesRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedPricesRefClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectedPricesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilterTree

&AtClient
Procedure FilterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectGoodsClient.FilterTreeSelection(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectionTreeWhenStateChanges(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		Return;
	ElsIf Result Then
		SelectGoodsClient.SelectionTreeWhenStateChanges(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTreeFilterOnChange(Item)
	
	SelectGoodsClient.FilterTreeFilterOnChange(ThisForm, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsHierarchyTree

&AtClient
Procedure ProductsHierarchyTreeSelectedOnChange(Item)
	
	CurrentData = Items.ProductsHierarchyTree.CurrentData;
	If CurrentData.Selected = 2 Then
		CurrentData.Selected = False;
	EndIf;
	
	SettingPricesClientServer.MarkRecursivelyDown(CurrentData);
	SettingPricesClientServer.MarkRecursivelyUpwards(CurrentData);
	
EndProcedure

&AtClient
Procedure TheHierarchyTreeOfItemPartnerSelectedOnChange(Item)
	
	CurrentData = Items.TheHierarchyTreeOfItemPartner.CurrentData;
	If CurrentData.Selected = 2 Then
		CurrentData.Selected = False;
	EndIf;
	
	SettingPricesClientServer.MarkRecursivelyDown(CurrentData);
	SettingPricesClientServer.MarkRecursivelyUpwards(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToPricing(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Cancel = False;
	If SettingKind = "Basic" Then
		If ValueIsFilled(TypeOfPriceSelection) Then
			If Not ValueIsFilled(PriceFrom) And Not ValueIsFilled(PriceUpTo) Then
				CommonClient.MessageToUser(
					NStr("vi = 'Chưa điền khoảng giá';
						|ru = 'Не заполнен диапазон цены';
						|en = 'Price range is not filled in'; fa = 'Price range is not filled in';
						|it = 'L''intervallo di prezzi non è compilato';
						|pl = 'Nie został wypełniony zakres ceny';
						|tr = 'Fiyat aralığı doldurulmadı'"),,"PriceFrom",,Cancel);
			EndIf;
			If ValueIsFilled(PriceFrom) And ValueIsFilled(PriceUpTo) And PriceUpTo < PriceFrom Then
				CommonClient.MessageToUser(
					NStr("vi = 'Biên dưới của khoảng giá không được lớn hơn biên trên';
						|ru = 'Нижний предел диапазона цен не должен превышать верхний предел диапазона цен';
						|en = 'Lower limit of price range shall not exceed the upper limit'; fa = 'Lower limit of price range shall not exceed the upper limit';
						|it = 'Il limite inferiore dell''intervallo di prezzi non deve superare il limite superiore dell''intervallo di prezzi';
						|pl = 'Dolna granica zakresu cen nie może przekraczać górną granicę zakresu cen';
						|tr = 'Fiyat aralığının alt sınırı, fiyat aralığının üst sınırını aşmamalıdır'"),,"PriceFrom",,Cancel);
			EndIf;
		Else
			If ValueIsFilled(PriceFrom) Or ValueIsFilled(PriceUpTo) Then
				CommonClient.MessageToUser(
					NStr("vi = 'Chưa chọn dạng giá';
						|ru = 'Не выбран вид цены';
						|en = 'Price type is not selected'; fa = 'Price type is not selected';
						|it = 'Nessun tipo di prezzo selezionato';
						|pl = 'Nie został wybrany rodzaj ceny';
						|tr = 'Fiyat türü seçilmedi'"),,"TypeOfPriceSelection",,Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisForm).Count() > 0 Then
		
		If SettingKind = "Basic" Then
			ConvertSimplifiedSetupToAdvancedOne(ThisForm);
		EndIf;
		
		NotifyChoice(PriceListSettings());
		
	Else
		CommonClient.MessageToUser(NStr("vi = 'Để chuyển đến đặt bảng giá, cần chọn một hoặc nhiều dạng giá';
										|ru = 'Для перехода к установке цен, необходимо выбрать один или несколько видов цен';
										|en = 'To go to the pricing, select one price type or more'; fa = 'To go to the pricing, select one price type or more';
										|it = 'Per procedere all''impostazione dei prezzi, è necessario selezionare uno o più tipi di prezzi';
										|pl = 'Aby przejść do ustalania cen, należy wybrać jeden lub więcej rodzajów cen.';
										|tr = 'Fiyat yapılandırmaya geçiş için bir veya daha fazla fiyat türü seçmeniz gerekmektedir'"),,"SelectedPrices");
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			SelectedPricesWereChanged = True;
			TableRow.Selected_5 = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			SelectedPricesWereChanged = True;
			TableRow.Selected_5 = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ResetFiltersByProperties(Command)
	
	ResetSelectionsByPropertiesOnServer();
	
EndProcedure

&AtClient
Procedure SelectionOfThePartnerSNomenclature(Command)
	
	Filter = New Structure("Owner", Object.Partner);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("CloseOnChoice", False);
	
	OpenForm("Catalog.ProductCrossReferences.ChoiceForm", FormParameters, Items.PartnerSNomenclatureTable);
	
EndProcedure

#Region Other

&AtClient
Procedure InformAboutImpossibilityOfSelection()
	ClearMessages();
	CurrentData = Items.SelectedPrices.CurrentData;
	CommonClient.MessageToUser(NStr("vi = 'Không có quyền đặt bảng giá theo dạng giá này';
									|ru = 'Нет прав на установку цен по данному виду цены';
									|en = 'No rights for pricing by this price type'; fa = 'No rights for pricing by this price type';
									|it = 'Nessun diritto di impostare i prezzi per questo tipo di prezzo';
									|pl = 'Brak uprawnień do ustalania cen dla tego rodzaju cen.';
									|tr = 'Bu fiyat türüne göre fiyat belirleme yetkisi yoktur'"),, "SelectedPrices[" + SelectedPrices.IndexOf(CurrentData) + "].Ref");
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedPrices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedPrices.DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilterPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.FixedValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.Filter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

EndProcedure

&AtServer
Procedure NavigationOptionWhenChangingOnServer()
	
	SelectGoodsServer.SetNavigationOptionPage(ThisForm);
	
	Items.ProductKind.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties);
	Items.ResetFiltersByProperties.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties);
	
	Items.CommandBarOfProductList.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives);
	Items.PartnerItemListCommandPanel.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.ByVendorPartNumbers);
	
EndProcedure

&AtServer
Procedure ProductKindOnChangeServer()

	SelectGoodsServer.FillInProductSelectionTree(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
// Adds a selection to the specified selection area collection.
//
// Parameters:
//	Selection area - Selection of the selected data - selection of the dynamic list,
//	Left value - String - path to the data of the selection field,
//	Legal value - Arbitrary - selection value,
//	Type of selection - Type of comparison of the combined data - type of comparison,
//	Representation - String - representation of the selection element.
//
Procedure AddFilterItem(SelectionArea, LeftValue, RightValue, TypeOfFilter, Presentation = "")
	
	FilterElement                   = SelectionArea.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue     = New DataCompositionField(LeftValue);
	FilterElement.RightValue    = RightValue;
	FilterElement.ViewMode  = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterElement.ComparisonType      = TypeOfFilter;
	
	If ValueIsFilled(Presentation) Then
		FilterElement.Presentation = Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure ResetSelectionsByPropertiesOnServer()
	
	SelectGoodsServer.ResetFiltersByProperties(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Function FindSelectionLines(SelectionTreeString, ItemArray)
	
	RowsArray = SelectionTreeString.GetItems();
	For Each String In RowsArray Do
		If String.Filter Then
			ItemArray.Add(String);
		EndIf;
		FindSelectionLines(String, ItemArray);
	EndDo;
	
EndFunction

&AtClientAtServerNoContext
Procedure CustomizeForm(ThisForm)
	
	SimplifiedSetting = (ThisForm.SettingKind = "Basic");
	
	If SimplifiedSetting Then
		ThisForm.Items.FilterOptions.CurrentPage = ThisForm.Items.FilterOptions.ChildItems.Basic;
	Else
		ThisForm.Items.FilterOptions.CurrentPage = ThisForm.Items.FilterOptions.ChildItems.Advanced;
	EndIf;
	
	ThisForm.Items.SelectedPricesAdvancedColumnSettingsGroup.Visible = Not SimplifiedSetting;
	ThisForm.Items.SelectedPricesAdvancedSettingsGroup.Visible        = Not SimplifiedSetting;
	
EndProcedure

&AtClient
Procedure GetProductGroupsRecursively(ProductGroups, RowsCollection)
	
	For Each TopLevelLines In RowsCollection Do
		
		If TopLevelLines.Selected = 1 Then
			ProductGroups.Add(TopLevelLines.Ref);
		EndIf;
		
		GetProductGroupsRecursively(ProductGroups, TopLevelLines.GetItems());
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetProductGroupsRecursively(ProductGroups, RowsCollection)
	
	For Each TopLevelLines In RowsCollection Do
		
		If ProductGroups <> Undefined Then
			IndexOf = ProductGroups.Find(TopLevelLines.Ref);
			TopLevelLines.Selected = (IndexOf <> Undefined);
			If IndexOf <> Undefined Then
				ProductGroups.Delete(IndexOf);
			EndIf;
		Else
			TopLevelLines.Selected = False;
		EndIf;
		
		SetProductGroupsRecursively(ProductGroups, TopLevelLines.GetItems());
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form)
	
	FilterParameters = New Structure("Filter", True);
	
	ReferenceNameProduct   = "Products.[";
	LinkNameCharacteristic = "Characteristic.[";
	
	SelectingListOfCharacteristics = Form.SettingsComposerFilter.Settings.Filter;
	SelectingListOfProducts = Form.SettingsComposerFilter.Settings.Filter;
	
	SetSelectionOfListOfCharacteristics = True;
	
	For Each SelectionTreeString In Form.FilterTree.GetItems() Do
		
		If SelectionTreeString.FilterAvailable Then
			
			If Not SelectionTreeString.Filter Then
				Continue;
			EndIf;
			
			// Depending on the type, set the value of the selection element.
			If TypeOf(SelectionTreeString.FilterValue) = Type("Boolean") Then
				
				If Not SelectionTreeString.FilterFeatures Then
					
					FilterElementName = SelectionTreeString.AttributeName;
					If SelectionTreeString.IsAddlAttribute Then
						FilterElementName = ReferenceNameProduct + SelectionTreeString.AttributeName + "]";
					EndIf;
					
					
					CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName, True, 
						DataCompositionComparisonType.Equal,,True, DataCompositionSettingsItemViewMode.Inaccessible);
				ElsIf SetSelectionOfListOfCharacteristics Then
					
					FilterElementName = SelectionTreeString.AttributeName;
					If SelectionTreeString.IsAddlAttribute Then
						FilterElementName = LinkNameCharacteristic + SelectionTreeString.AttributeName + "]";
					EndIf;
					
					CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName, True, 
						DataCompositionComparisonType.Equal,,True, DataCompositionSettingsItemViewMode.Inaccessible);
				EndIf; 
				
			ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("Date") 
				Or TypeOf(SelectionTreeString.FilterValue) = Type("Number") Then
				
				If ValueIsFilled(SelectionTreeString.IntervalFrom) Then
					
					If Not SelectionTreeString.FilterFeatures Then
						
						FilterElementName = SelectionTreeString.AttributeName;
						If SelectionTreeString.IsAddlAttribute Then
							FilterElementName = ReferenceNameProduct + SelectionTreeString.AttributeName + "]";
						EndIf;
						
						AddFilterItem(SelectingListOfProducts, FilterElementName, SelectionTreeString.IntervalFrom, 
							DataCompositionComparisonType.GreaterOrEqual);
					ElsIf SetSelectionOfListOfCharacteristics Then
						
						FilterElementName = SelectionTreeString.AttributeName;
						If SelectionTreeString.IsAddlAttribute Then
							FilterElementName = LinkNameCharacteristic + SelectionTreeString.AttributeName + "]";
						EndIf;
						
						AddFilterItem(SelectingListOfCharacteristics, FilterElementName, SelectionTreeString.IntervalFrom, 
							DataCompositionComparisonType.GreaterOrEqual);
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(SelectionTreeString.IntervalTo) Then
					
					If Not SelectionTreeString.FilterFeatures Then
						
						FilterElementName = SelectionTreeString.AttributeName;
						If SelectionTreeString.IsAddlAttribute Then
							FilterElementName = ReferenceNameProduct + SelectionTreeString.AttributeName + "]";
						EndIf;
						
						AddFilterItem(SelectingListOfProducts, FilterElementName, SelectionTreeString.IntervalTo, 
							DataCompositionComparisonType.LessOrEqual);
					ElsIf SetSelectionOfListOfCharacteristics Then
						
						FilterElementName = SelectionTreeString.AttributeName;
						If SelectionTreeString.IsAddlAttribute Then
							FilterElementName = LinkNameCharacteristic + SelectionTreeString.AttributeName + "]";
						EndIf;
						
						AddFilterItem(SelectingListOfCharacteristics, FilterElementName, SelectionTreeString.IntervalTo, 
							DataCompositionComparisonType.LessOrEqual);
					EndIf;
					
				EndIf;
				
			ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("String") Then
				
				If Not SelectionTreeString.FilterFeatures Then
					
					FilterElementName = SelectionTreeString.AttributeName;
					If SelectionTreeString.IsAddlAttribute Then
						FilterElementName = ReferenceNameProduct + SelectionTreeString.AttributeName + "]";
					EndIf;
					
					CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName, 
						SelectionTreeString.FilterValue, DataCompositionComparisonType.Equal,,True);
				ElsIf SetSelectionOfListOfCharacteristics Then
					
					FilterElementName = SelectionTreeString.AttributeName;
					If SelectionTreeString.IsAddlAttribute Then
						FilterElementName = LinkNameCharacteristic + SelectionTreeString.AttributeName + "]";
					EndIf;
					
					CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName, 
						SelectionTreeString.FilterValue, DataCompositionComparisonType.Equal,,True);
				EndIf;
				
			EndIf;
			
		Else
			
			// Selection is not available - it is a selection row that has subordinate rows.
			RowsArray = New Array; 
			FindSelectionLines(SelectionTreeString, RowsArray);
			If RowsArray.Count() = 0 Then
				Continue;
			EndIf;
			
			FIlterRow = RowsArray[0];
			
			// Set the selection by the values of the subordinate rows of the selection tree row.
			If Not FIlterRow.FilterFeatures Then 
				
				FilterElementName = "Products." + FIlterRow.AttributeName;
				If FIlterRow.IsAddlAttribute Then
					FilterElementName = ReferenceNameProduct + FIlterRow.AttributeName + "]";
				EndIf;
				
				SetSelectionBySelectionTreeRows(FilterElementName, SelectingListOfProducts, RowsArray);
			ElsIf SetSelectionOfListOfCharacteristics Then
				
				FilterElementName = "Characteristic." + FIlterRow.AttributeName;
				If FIlterRow.IsAddlAttribute Then
					FilterElementName = LinkNameCharacteristic + FIlterRow.AttributeName + "]";
				EndIf;
				
				SetSelectionBySelectionTreeRows(FilterElementName, SelectingListOfCharacteristics, RowsArray);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
// Sets the selection by a list of values from the rows of the selection tree.
//
// Parameters:
//	Selection Element name - String - name of the selection element,
//	Selection - Selection of the selected items - collection of items of the selection of the list of nomenclature,
//	The selection tree string is an array - an array of rows of the selection tree.
//
Procedure SetSelectionBySelectionTreeRows(FilterElementName, Filter, SelectionTreeRows_)
	
	SelectionValues = New Array;
	For Each String In SelectionTreeRows_ Do
		SelectionValues.Add(String.FilterValue);
	EndDo;
	
	CommonClientServer.SetFilterItem(Filter, FilterElementName, SelectionValues, DataCompositionComparisonType.InList, , True);
	
EndProcedure

&AtServer
// Sets the selection for the list of items based on similar properties of the item type of the transferred product.
//
// Parameters:
//	Form - Client Application form - Nomenclature list form or selection form,
//	Nomenclature - Reference link.Nomenclature - a product by the values of the properties of which it is necessary to set the selection of the list of nomenclature.
//
Procedure FilterBySimilarProperties(Form, Products)
	
	// Set the navigation option - "by properties".
	Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties;
	SelectGoodsServer.SetNavigationOptionPage(ThisForm);
	
	// Set the type of nomenclature and fill in the selection tree.
	Form.ProductKind = Common.ObjectAttributeValue(Products, "ProductKind");
	SelectGoodsServer.FillInProductSelectionTree(ThisForm);
	
	// Get a list of properties and values of the item type of the current product..
	PropertiesForSelectingProductsWithSimilarProperties = SelectGoodsServer.PropertiesForSelectingProductsWithSimilarProperties(Products);
	
	FilterTree1 = Form.FormAttributeToValue("FilterTree");
	
	// Go through the resulting list of properties, put down the usage flags.
	For Each AdditionalProperty In PropertiesForSelectingProductsWithSimilarProperties Do
		
		For Each Property In FilterTree1.Rows Do
			
			If ValueIsFilled(Property.AttributeName) Then
				Continue;
			EndIf;
			
			For Each PropertyValue In Property.Rows Do
				
				If Not (AdditionalProperty.Presentation = Property.Presentation) Then
					Continue;
				EndIf;
				
				// Enable the use of the property in the selection if the value of the selection tree is similar 
				// to the value of the list of properties of the current item type.
				PropertyValue.Filter = (PropertyValue.FilterValue = AdditionalProperty.Value);
				
				If PropertyValue.Filter Then
					Property.Filter = True;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Form.ValueToFormAttribute(FilterTree1, "FilterTree");
	
	// The checkboxes are placed, now apply selections to the list of items.
	EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form);
	
EndProcedure

&AtServer
Function PriceListSettings()
	
	SettingPricesServer.SaveSettingsForOrderOfSupplierPriceTypes(ThisForm);
	
	StructureOfData = New Structure;
	StructureOfData.Insert("Partner", Object.Partner);
	StructureOfData.Insert("ComposerSettings", SettingsComposerFilter.Settings);
	StructureOfData.Insert("SelectedPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisForm));
	StructureOfData.Insert("Date", EndOfDay(Date));
	StructureOfData.Insert("SettingKind", SettingKind);
	StructureOfData.Insert("NavigationOption",NavigationOption);
	StructureOfData.Insert("ProductKind",ProductKind);
	StructureOfData.Insert("FilterParametersTable", FilterParametersTable.Unload());
	
	Return PutToTempStorage(StructureOfData, UUID);
	
EndFunction

&AtClientAtServerNoContext
Function ConvertAdvancedSettingToSimplifiedOne(Form)

	StandardFields = New Array;
	StandardFields.Add("ProductSegment");
	StandardFields.Add("Price");
	
	SimplifiedSetting = New Structure;
	SimplifiedSetting.Insert("SettingsWillBeLost", False);
	SimplifiedSetting.Insert("ProductSegment", Undefined);
	SimplifiedSetting.Insert("PlanningObject", Undefined);
	SimplifiedSetting.Insert("OnlyInStock",  False);
	SimplifiedSetting.Insert("PriceUpTo",  Undefined);
	SimplifiedSetting.Insert("PriceFrom",  Undefined);
	SimplifiedSetting.Insert("TypeOfPriceSelection", Undefined);
	SimplifiedSetting.Insert("ProductGroups", Undefined);
	SimplifiedSetting.Insert("PartnerProductGroups", Undefined);
	SimplifiedSetting.Insert("PartnerProducts", Undefined);
	SimplifiedSetting.Insert("Products", Undefined);
	
	ProductSegmentField    = New DataCompositionField("ProductSegment");
	PriceField                   = New DataCompositionField("Price");
	PriceFromField                 = New DataCompositionField("PriceFrom");
	PriceBeforeField                 = New DataCompositionField("PriceUpTo");
	FieldBalance                = New DataCompositionField("Balance");
	SalesAllowedField       = New DataCompositionField("SalesAllowed");
	ProductsField           = New DataCompositionField("Products");
	PartnerProductField = New DataCompositionField("PartnerProducts");
	ProductTypeField      = New DataCompositionField("Products.ProductKind");
	PlanningObjectField   = New DataCompositionField("PlanningObject");
	PriceViewRangeField      = New DataCompositionField("PriceTypeRange");
	ParentProductField           = New DataCompositionField("Products.Parent");
	ParentPartnerProductField = New DataCompositionField("PartnerProducts.Parent");
	
	
	For Each FilterElement In Form.SettingsComposerFilter.Settings.Filter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If FilterElement.Use And FilterElement.Items.Count() > 0 Then
				SimplifiedSetting.SettingsWillBeLost = True;
			EndIf;
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(ProductSegmentField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use And SimplifiedSetting.ProductSegment = Undefined  Then
				SimplifiedSetting.ProductSegment = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.ProductSegment <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(SalesAllowedField) Then
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PlanningObjectField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use And SimplifiedSetting.PlanningObject = Undefined  Then
				SimplifiedSetting.PlanningObject = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.PlanningObject <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(FieldBalance)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Greater
			And FilterElement.RightValue = 0 Then
			
			If FilterElement.Use And SimplifiedSetting.PlanningObject = Undefined  Then
				SimplifiedSetting.OnlyInStock = True;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.OnlyInStock <> False);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PriceViewRangeField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use And SimplifiedSetting.TypeOfPriceSelection = Undefined  Then
				SimplifiedSetting.TypeOfPriceSelection = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.TypeOfPriceSelection <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PriceBeforeField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
			
			If FilterElement.Use And SimplifiedSetting.PriceUpTo = Undefined  Then
				SimplifiedSetting.PriceUpTo = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.PriceUpTo <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PriceFromField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
			
			If FilterElement.Use And SimplifiedSetting.PriceFrom = Undefined  Then
				SimplifiedSetting.PriceFrom = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.PriceFrom <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If Not Form.UsePartnersProducts
			And String(FilterElement.LeftValue) = String(ParentProductField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.ProductGroups = Undefined  Then
				SimplifiedSetting.ProductGroups = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.ProductGroups <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If Form.UsePartnersProducts
			And String(FilterElement.LeftValue) = String(ParentPartnerProductField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.PartnerProductGroups = Undefined  Then
				SimplifiedSetting.PartnerProductGroups = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.PartnerProductGroups <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(ProductsField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.Products= Undefined  Then
				SimplifiedSetting.Products = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.Products <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PartnerProductField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.PartnerProducts = Undefined  Then
				SimplifiedSetting.PartnerProducts = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.PartnerProducts <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If Not SimplifiedSetting.SettingsWillBeLost And FilterElement.Use Then 
			SimplifiedSetting.SettingsWillBeLost = True;
		EndIf;
		
	EndDo;
	
	Return SimplifiedSetting;
	
EndFunction

&AtClient
Procedure ConvertSimplifiedSetupToAdvancedOne(Form)

	Form.SettingsComposerFilter.Settings.Filter.Items.Clear();
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties") Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"Products.ProductKind",
			DataCompositionComparisonType.Equal,
			Form.ProductKind,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form);
		
	EndIf;
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.RemainingGoodsByShelfLives")
		And Form.ItemList.Count() > 0 Then
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"Products",
			DataCompositionComparisonType.InList,
			Form.ItemList,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByVendorPartNumbers")
		And Form.PartnerSNomenclatureTable.Count() > 0 Then
		
		ListOfPartnerProducts = New ValueList;
		For Each TSRow In Form.PartnerSNomenclatureTable Do
			ListOfPartnerProducts.Add(TSRow.Ref);
		EndDo;
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PartnerProducts",
			DataCompositionComparisonType.InList,
			ListOfPartnerProducts,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
		ProductGroups = New ValueList;
		GetProductGroupsRecursively(ProductGroups, Form.ProductsHierarchyTree.GetItems());
		
		If ProductGroups.Count() > 0 Then
			CommonClientServer.AddCompositionItem(
				Form.SettingsComposerFilter.Settings.Filter,
				"Products.Parent",
				DataCompositionComparisonType.InList,
				ProductGroups,
				Undefined,
				True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
	EndIf;
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByVendorHierarchy") Then
		ProductGroups = New ValueList;
		GetProductGroupsRecursively(ProductGroups, Form.TheHierarchyTreeOfItemPartner.GetItems());
		
		If ProductGroups.Count() > 0 Then
			CommonClientServer.AddCompositionItem(
				Form.SettingsComposerFilter.Settings.Filter,
				"PartnerProducts.Parent",
				DataCompositionComparisonType.InList,
				ProductGroups,
				Undefined,
				True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
	EndIf;
	
	If ValueIsFilled(Form.ProductSegment) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"ProductSegment",
			DataCompositionComparisonType.Equal,
			Form.ProductSegment,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
	If ValueIsFilled(Form.PlanningObject) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PlanningObject",
			DataCompositionComparisonType.Equal,
			Form.PlanningObject,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"SalesAreAllowed",
			DataCompositionComparisonType.Equal,
			True,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
	If Form.OnlyInStock Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"Balance",
			DataCompositionComparisonType.Greater,
			0,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
	If ValueIsFilled(Form.TypeOfPriceSelection) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PriceTypeRange",
			DataCompositionComparisonType.Equal,
			Form.TypeOfPriceSelection,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
	If ValueIsFilled(Form.PriceFrom) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PriceFrom",
			DataCompositionComparisonType.GreaterOrEqual,
			Form.PriceFrom,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
	If ValueIsFilled(Form.PriceUpTo) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PriceUpTo",
			DataCompositionComparisonType.LessOrEqual,
			Form.PriceUpTo,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
EndProcedure


&AtClientAtServerNoContext
Procedure AutoTagBlankContent(Form)
	
	Form.Items.TypeOfPriceSelection.AutoMarkIncomplete = ValueIsFilled(Form.PriceFrom) Or ValueIsFilled(Form.PriceUpTo);
	Form.Items.PriceFrom.AutoMarkIncomplete = ValueIsFilled(Form.TypeOfPriceSelection) And (Not ValueIsFilled(Form.PriceUpTo) And Not ValueIsFilled(Form.PriceFrom));
	Form.Items.PriceUpTo.AutoMarkIncomplete = ValueIsFilled(Form.TypeOfPriceSelection) And (Not ValueIsFilled(Form.PriceUpTo) And Not ValueIsFilled(Form.PriceFrom));
	
	If Not Form.Items.PriceFrom.AutoMarkIncomplete Then
		Form.Items.PriceFrom.MarkIncomplete = False;
	EndIf;
	If Not Form.Items.PriceUpTo.AutoMarkIncomplete Then
		Form.Items.PriceUpTo.MarkIncomplete = False;
	EndIf;
	If Not Form.Items.TypeOfPriceSelection.AutoMarkIncomplete Then
		Form.Items.TypeOfPriceSelection.MarkIncomplete = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure BuildHierarchyOfProducts(Rows, TreeRow)
	
	For Each TSRow In Rows Do
		
		If ValueIsFilled(TSRow.Parent) And TSRow.Parent.Ref = TSRow.Ref Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(TSRow.Ref) Then
			BuildHierarchyOfProducts(TSRow.Rows, TreeRow);
			Continue;
		EndIf;
		
		NewRow = TreeRow.Rows.Add();
		FillPropertyValues(NewRow, TSRow);
		BuildHierarchyOfProducts(TSRow.Rows, NewRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnerSNomenclatureTable.Clear();
	
	SettingPricesServer.InitializeSelectedPrices(ThisForm);
	
	InitializePartnerProductHierarchyTree();
	
EndProcedure

&AtClient
Procedure PartnerSNomenclatureTableChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NewRow = PartnerSNomenclatureTable.Add();
	NewRow.Ref = ValueSelected;
	
EndProcedure

&AtServer
Procedure InitializePartnerProductHierarchyTree()
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref,
	|	T.Description AS Description,
	|	FALSE AS Selected
	|FROM
	|	Catalog.ProductCrossReferences AS T
	|WHERE
	|	T.IsFolder
	|	AND T.Owner = &Partner
	|TOTALS BY
	|	Ref HIERARCHY");
	
	Tree = FormAttributeToValue("TheHierarchyTreeOfItemPartner");
	
	Tree.Rows.Clear();
	
	NewRow = Tree.Rows.Add();
	NewRow.Description = NStr("vi = 'Nhóm gốc mặt hàng';
								|ru = 'Корневая группа номенклатуры';
								|en = 'Items root group'; fa = 'Items root group';
								|it = 'Il gruppo principale di articoli';
								|pl = 'Podstawowa grupa nomenklatury';
								|tr = 'Ürünlerin kök grubu'");
	
	Query.Parameters.Insert("Partner", Object.Partner);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	BuildHierarchyOfProducts(Result.Rows, NewRow);
	ValueToFormData(Tree, TheHierarchyTreeOfItemPartner);
	
EndProcedure

&AtServer
Procedure InitializeProductHierarchyTree()
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref,
	|	T.Description AS Description,
	|	FALSE AS Selected
	|FROM
	|	Catalog.Products AS T
	|WHERE
	|	T.IsFolder
	|TOTALS BY
	|	T.Ref HIERARCHY
	|");
	
	Tree = FormAttributeToValue("ProductsHierarchyTree");
	
	Tree.Rows.Clear();
	
	NewRow = Tree.Rows.Add();
	NewRow.Description = NStr("vi = 'Nhóm gốc mặt hàng';
								|ru = 'Корневая группа номенклатуры';
								|en = 'Items root group'; fa = 'Items root group';
								|it = 'Il gruppo principale di articoli';
								|pl = 'Podstawowa grupa nomenklatury';
								|tr = 'Ürünlerin kök grubu'");
	
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	BuildHierarchyOfProducts(Result.Rows, NewRow);
	ValueToFormData(Tree, ProductsHierarchyTree);
	
EndProcedure

&AtClient
Procedure SettingsWillBeLostCompletion(QuestionResult, AdditionalParameters) Export
	
	SimplifiedSetting = AdditionalParameters.SimplifiedSetting;
	
	If QuestionResult = "Continue" Then
		ViewSettingsWhenChangingFragment(SimplifiedSetting);
	EndIf;
	
	If QuestionResult = "Cancel" Then
		SettingKind = "Advanced";
		CustomizeForm(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewSettingsWhenChangingFragment(Val SimplifiedSetting)
	
	FillPropertyValues(ThisForm, SimplifiedSetting);
	CustomizeForm(ThisForm);
	
	SetProductGroupsRecursively(SimplifiedSetting.ProductGroups, ProductsHierarchyTree.GetItems());
	
EndProcedure

&AtServer
Procedure ReReadVendorPriceTypesOnServer()
	
	SettingPricesServer.ReReadSelectedPrices(ThisForm);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
