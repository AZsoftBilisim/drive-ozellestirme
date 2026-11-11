
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TreeSelectedPricesDisplayGroups 				= True;
	TheTreeSelectedPricesDisplayOnlySelectedItems 	= False;
	PriceSettingOption 							= 3;
	OptionForSettingThePrice 				= 3;
	AvailabilityOption 									= 3;

	FormCode          = "Processing_PriceList_ConfigurationForm";
	
	// For the efficiency of procedures for the selection of goods.
	UseFilters = True;
	FlagOfOpeningAForm = True;
	
	//Use Price groups = Get a functional option ("Use Price groups");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	UseSeveralPriceTypes          = GetFunctionalOption("UseSeveralPriceTypes");
	UsePriceManagementSystem25          = PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);

	// initializing the linker by nomenclature (setting up lines)
	Query = New Query(
	"
	|SELECT
	|	Ref AS Ref,
	|	Description AS Description,
	|	FALSE AS Selected
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	IsFolder
	|ORDER BY
	|	Description
	|TOTALS BY
	|	Ref HIERARCHY
	|");
	
	Tree = FormAttributeToValue("ProductsHierarchyTree", Type("ValueTree"));
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

	StructureOfData = GetFromTempStorage(Parameters.PriceListSettings);
	SettingPricesServer.LoadDefaultSelectionSettings(ThisObject);
	SettingsComposerFilter.LoadSettings(StructureOfData.ComposerSettings);

	StructureOfData.Property("PriceSettingOption", PriceSettingOption);
	StructureOfData.Property("OptionForSettingThePrice", OptionForSettingThePrice);
	StructureOfData.Property("AvailabilityOption", AvailabilityOption);
	If PriceSettingOption = 0 Then
		PriceSettingOption = 3;
	EndIf;
	If OptionForSettingThePrice = 0 Then
		OptionForSettingThePrice = 3;
	EndIf;
	If AvailabilityOption = 0 Then
		AvailabilityOption = 3;
	EndIf;
		
	DataCompositionSchema = DataProcessors.PriceList.GetTemplate("RelevantPriceTypes");
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema);
	SettingsBuilderColumnSelection.Initialize(SettingsSource);
	SelectedFields = StructureOfData.ColumnComposerSettings.Selection; // DataCompositionSelectedFields 
	If StructureOfData.Property("ColumnComposerSettings")
		And SelectedFields.Items.Count() > 0 Then
		SettingsBuilderColumnSelection.LoadSettings(StructureOfData.ColumnComposerSettings);
	Else
		SettingsBuilderColumnSelection.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	ArrayOfPriceTypes = New Array;
	For Each TSRow In StructureOfData.SelectedPrices Do //ValueTableRow
		ArrayOfPriceTypes.Add(TSRow.Ref);
	EndDo;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject, ArrayOfPriceTypes);
	For Each TSRow In StructureOfData.SelectedPrices Do //ValueTableRow
		If TSRow <> Undefined Then
			FoundTypeOfPrices = SettingPricesClientServer.FindPriceTypeString(SelectedPrices, TSRow.Ref);
			If FoundTypeOfPrices = Undefined Then
				Continue;
			EndIf;
			FillPropertyValues(FoundTypeOfPrices, TSRow);
		EndIf;
	EndDo;
	
	Tree = FillInTreeOfPriceTypes(StructureOfData.SelectedPrices);
	ValueToFormData(Tree, TheTreeSelectedPrices);
	
	Date = StructureOfData.Date;
	
	ProductKind = StructureOfData.ProductKind;
	FilterParametersTable.Load(StructureOfData.FilterParametersTable);
	SelectGoodsServer.FillInProductSelectionTree(ThisObject);

	NavigationOption = StructureOfData.NavigationOption;
	If Not ValueIsFilled(NavigationOption) Then
		NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy;
	EndIf;
	NavigationOptionWhenChangingOnServer();
	
	StructureOfData.Property("GroupingOption",GroupingOption);
	If Not ValueIsFilled(GroupingOption) Then
		GroupingOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives;
	EndIf;
	
	FilterParametersTable.Load(StructureOfData.FilterParametersTable);
	
	AddressOfTheStorageOfLayoutSchemeParametersByPriceType = StructureOfData.AddressOfTheStorageOfLayoutSchemeParametersByPriceType;
	StorageAddressDataLayoutSettings = StructureOfData.StorageAddressDataLayoutSettings;

	SimplifiedSetting = ConvertAdvancedSettingToSimplifiedOne(ThisObject);
	FillPropertyValues(ThisObject, SimplifiedSetting);
	
	AutoTagBlankContent(ThisObject);
	
	If ValueIsFilled(Parameters.GoodsWithSimilarProperties) Then
		
		FilterBySimilarProperties(ThisObject, Parameters.GoodsWithSimilarProperties.Products);
		SettingKind = "Basic";
		CustomizeForm(ThisObject);
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.Filters;
		
	Else
		
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
		
		SetProductGroupsRecursively(SimplifiedSetting.ProductGroups, ProductsHierarchyTree.GetItems());
		
		CustomizeForm(ThisObject);
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	WhenChangingAvailabilityOption();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangingTypeOfPrices" Then
		
		UpdateSettingsForPriceTypes();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If NavigationOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives Then
		
		SearchForEmptyItem = ItemList.FindByValue(Catalogs.Products.EmptyRef());
		If SearchForEmptyItem <> Undefined Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Mặt hàng""';
							|ru = 'Поле ""Номенклатура"" не заполнено';
							|en = '""Product"" is not filled in'; fa = '""Product"" is not filled in';
							|it = 'Il campo ""Articolo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Номенклатура""';
							|tr = '""Ürün gamı"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(ErrorText,,
				"ItemList",,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Function AdvancedSettingsWillBeLost()
	
	WillBeLost = False;
	If OptionForSettingThePrice <> 3	Then 
		WillBeLost = True;	
	EndIf;	
	
	Return WillBeLost;	
	
EndFunction

&AtClient
Procedure SettingKindOnChange(Item)
	
	ClearMessages();
	
	SimplifiedSetting = (SettingKind = "Basic");
	If SimplifiedSetting Then
		
		SimplifiedSetting = ConvertAdvancedSettingToSimplifiedOne(ThisObject);
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
		
		AutoTagBlankContent(ThisObject);
		
	Else
		
		If AdvancedSettingsWillBeLost() Then	
			MessageText = NStr("vi = 'Chỉ có thể soạn bộ lọc [Цена должна быть] dưới dạng đơn giản.';
								|ru = 'Редактирование отбора [Цена должна быть] возможно только в простом виде.';
								|en = 'Editing the [The price should be] filter is only available in a simple form.'; fa = 'Editing the [The price should be] filter is only available in a simple form.';
								|it = 'La modifica del filtro [il prezzo deve essere] è possibile solamente nel tipo standard.';
								|pl = 'Edycja filtru [Cena powinna być] jest możliwe tylko w prostym wyglądzie.';
								|tr = 'Filtrenin düzenlenmesi [Fiyat olmalı] sadece basit türde mümkündür.'");
			Message(MessageText);
		EndIf;
		
		ConvertSimplifiedSetupToAdvancedOne(ThisObject);
		CustomizeForm(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsWillBeLostCompletion(QuestionResult, AdditionalParameters) Export
	
	SimplifiedSetting = AdditionalParameters.SimplifiedSetting;
	
	If QuestionResult = "Continue" Then
		ViewSettingsWhenChangingFragment(SimplifiedSetting);
	EndIf;
	
	If QuestionResult = "Cancel" Then
		SettingKind = "Advanced";
		CustomizeForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewSettingsWhenChangingFragment(Val SimplifiedSetting)
	
	FillPropertyValues(ThisObject, SimplifiedSetting);
	WhenChangingAvailabilityOption();
	CustomizeForm(ThisObject);
	
	SetProductGroupsRecursively(SimplifiedSetting.ProductGroups, ProductsHierarchyTree.GetItems());
	
EndProcedure

&AtClient
Procedure PriceFromOnChange(Item)
	AutoTagBlankContent(ThisObject);
EndProcedure

&AtClient
Procedure PriceUpToOnChange(Item)
	AutoTagBlankContent(ThisObject);
EndProcedure

&AtClient
Procedure NavigationOptionOnChange(Item)
	
	NavigationOptionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductKindOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedPrices

&AtClient
Procedure TheTreeSelectedPricesRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesRefClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesSelection(Item, RowSelected, Field, StandardProcessing)
		
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		If Not CurrentData.IsFolder Then
			If Field = Items.TheTreeSelectedPricesInfluencingPrices Then
				If CurrentData.InfluencingPrices.Count() > 0 Then
					ShowValue(Undefined, CurrentData.InfluencingPrices);
				EndIf;
			ElsIf Field = Items.TheTreeSelectedPricesDependentPrices Then	
					If CurrentData.DependentPrices.Count() > 0 Then
						ShowValue(Undefined, CurrentData.DependentPrices);
					EndIf;
			ElsIf Field = Items.TheTreeSelectedPricesParameters Then
				EditSettings(Commands["EditSettings"]);			
			Else
				ShowValue(Undefined, CurrentData.Ref);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilterTree

&AtClient
Procedure FilterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectGoodsClient.FilterTreeSelection(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionTreeWhenStateChanges(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		Return;
	ElsIf Result Then
		SelectGoodsClient.SelectionTreeWhenStateChanges(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTreeFilterOnChange(Item)
	
	SelectGoodsClient.FilterTreeFilterOnChange(ThisObject, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

#EndRegion

#Region EventHandlersOfTableElementsComposerOfTableSettingsSettings

&AtClient
Procedure SettingsComposerSettingsFilterSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "SettingsComposerSettingsFilterRightValue" Then 
		FilterElement = SettingsComposerFilter.Settings.Filter.GetObjectByID(RowSelected);
		If FilterElement <> Undefined And TypeOf(FilterElement.RightValue) = Type("CatalogRef.TypesOfPrices")  Then
			NewParameter1 = New ChoiceParameter("Filter.IsFolder", "False"); 
			FilterArray = New Array();
			FilterArray.Add(NewParameter1);
			Field.ChoiceParameters = New FixedArray(FilterArray);
		EndIf;
	EndIf;
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToPricing(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(ThisObject);
	
	Cancel = False;
	If SettingKind = "Basic" Then
		If ValueIsFilled(TypeOfPriceSelection) Then
			If Not ValueIsFilled(PriceFrom) And Not ValueIsFilled(PriceUpTo) Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền khoảng giá';
						|ru = 'Не заполнен диапазон цены';
						|en = 'Price range is not filled in'; fa = 'Price range is not filled in';
						|it = 'L''intervallo di prezzi non è compilato';
						|pl = 'Nie został wypełniony zakres ceny';
						|tr = 'Fiyat aralığı doldurulmadı'"),,"PriceFrom",,Cancel);
			EndIf;
			If ValueIsFilled(PriceFrom) And ValueIsFilled(PriceUpTo) And PriceUpTo < PriceFrom Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Biên dưới của khoảng giá không được lớn hơn biên trên';
						|ru = 'Нижний предел диапазона цен не должен превышать верхний предел диапазона цен';
						|en = 'Lower limit of price range shall not exceed the upper limit'; fa = 'Lower limit of price range shall not exceed the upper limit';
						|it = 'Il limite inferiore dell''intervallo di prezzi non deve superare il limite superiore dell''intervallo di prezzi';
						|pl = 'Dolna granica zakresu cen nie może przekraczać górną granicę zakresu cen';
						|tr = 'Fiyat aralığının alt sınırı, fiyat aralığının üst sınırını aşmamalıdır'"),,"PriceFrom",,Cancel);
			EndIf;
		Else
			If ValueIsFilled(PriceFrom) Or ValueIsFilled(PriceUpTo) Then
				CommonClientServer.MessageToUser(
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
	
	If SettingPricesClientServer.DependentPricesNotSelected(ThisObject) Then
		
		ShowQueryBox(New CallbackDescription("GoToPricingCompletion", ThisObject), NStr("vi = 'Đã tìm thấy các dạng giá phụ thuộc vào các dạng giá đã chọn. Chọn tất cả các dạng giá phụ thuộc?';
																						|ru = 'Найдены зависимые от выбранных виды цен. Выбрать все зависимые цены?';
																						|en = 'Price types that depend on the selected ones are found. Select all the dependent prices?'; fa = 'Price types that depend on the selected ones are found. Select all the dependent prices?';
																						|it = 'Trovati i tipi di prezzi subordinati a quelli selezionati. Selezionare tutti i prezzi subordinati?';
																						|pl = 'Znaleziono w zależności od wybranych typów cen. Wybrac wszystkie ceny zależne?';
																						|tr = 'Seçilen fiyat türlerine bağlı olarak fiyat türleri bulundu. Tüm bağlı fiyatlar seçilsin mi?'"), QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoToSettingPricesFragment();
	
EndProcedure

&AtClient
Procedure GoToPricingCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.Yes Then
        SettingPricesClientServer.SelectAllDependentPrices_(ThisObject);
        SettingPricesClientServer.SelectAllInfluencingPrices_(ThisObject);
    EndIf;
    
    
    GoToSettingPricesFragment();

EndProcedure

&AtServer
Procedure RecordDetailsForOrdering(Result)
	TabPrices = FormAttributeToValue("SelectedPrices",Type("ValueTable"));
	
	For Each Page1 In TabPrices Do
		Page1.AddlOrderingAttribute = 0;
	EndDo;
	Indus=1;
	
	For Each Page1 In Result Do
		PriceSelectionRow = TabPrices.FindRows(New Structure("Ref",Page1.PriceKind));
		For Each It_ In PriceSelectionRow Do
			Row1_ = It_;
			Row1_.AddlOrderingAttribute = Indus;
			Indus = Indus+1;
		EndDo;
	EndDo;
	ValueToFormData(TabPrices,SelectedPrices);
	
EndProcedure

&AtServer
Procedure LoadResultsOfColumnSettingsLayout()
	
	FilterScheme = DataProcessors.PriceList.GetTemplate("RelevantPriceTypes");

	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(FilterScheme));
	SettingsComposer.LoadSettings(SettingsBuilderColumnSelection.Settings);

	TemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = TemplateComposer.Execute(FilterScheme, SettingsComposer.GetSettings(),,,
		Type("DataCompositionValueCollectionTemplateGenerator"), False);
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);

	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Result = OutputProcessor.Output(DataCompositionProcessor);
	RecordDetailsForOrdering(Result);

EndProcedure

&AtClient
Procedure GoToSettingPricesFragment()
	
	If Not SettingPricesClient.RequiredDataLayoutSchemaParametersFilledIn(ThisObject) Then
		Return;
	EndIf;
	
	If SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject).Count() > 0 Then
		
		If SettingKind = "Basic" Then
			ConvertSimplifiedSetupToAdvancedOne(ThisObject);
		EndIf;
		
		SetColumnLayoutParameters();
		LoadResultsOfColumnSettingsLayout();
		NotifyChoice(PriceListSettings());
		
	Else
		CommonClientServer.MessageToUser(NStr("vi = 'Để chuyển đến đặt bảng giá, cần chọn một hoặc nhiều dạng giá';
												|ru = 'Для перехода к установке цен, необходимо выбрать один или несколько видов цен';
												|en = 'To go to the pricing, select one price type or more'; fa = 'To go to the pricing, select one price type or more';
												|it = 'Per procedere all''impostazione dei prezzi, è necessario selezionare uno o più tipi di prezzi';
												|pl = 'Aby przejść do ustalania cen, należy wybrać jeden lub więcej rodzajów cen.';
												|tr = 'Fiyat yapılandırmaya geçiş için bir veya daha fazla fiyat türü seçmeniz gerekmektedir'"),,"SelectedPrices");
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllTreeTypesOfPrices(Command)
	
	SetSelectionValuesForAllTreeElements(True);
	
EndProcedure

&AtClient 
Procedure SetSelectionValuesForAllTreeElements(On_)
	
	For Each CurrentData In TheTreeSelectedPrices.GetItems() Do
		If Not CurrentData.IsFolder Then
			CurrentData.Selected = On_;
			CurrentData.Edit = On_;
		Else
			SettingPricesClientServer.SetValueRecursivelyToAllElementsOfParent(CurrentData,On_);
		EndIf;
	EndDo;

	For Each String In SelectedPrices Do
		String.Selected_5 = On_;
		String.Edit = On_;
	EndDo;
		
EndProcedure

&AtServer
Procedure ReFillTreeWithSelectedPrices()
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));
	Tree.Rows.Clear();
	ValueToFormData(Tree, TheTreeSelectedPrices);	
	TableOfSelectedPrices =  FormAttributeToValue("SelectedPrices", Type("ValueTable"));
	Tree = FillInTreeOfPriceTypes(TableOfSelectedPrices);
	ValueToFormData(Tree, TheTreeSelectedPrices);	
	
EndProcedure

&AtClient
Procedure DisplayOnlySelectedItems(Command)
	
	TheTreeSelectedPricesDisplayOnlySelectedItems = Not TheTreeSelectedPricesDisplayOnlySelectedItems;
	ReFillTreeWithSelectedPrices();
	ExpandSelectedPricesTree();
	
EndProcedure

&AtClient
Procedure ExpandSelectedPricesTree()
	
	If TreeSelectedPricesDisplayGroups Then
		TreeItems = TheTreeSelectedPrices.GetItems();
		For Each TreeItem In TreeItems Do
			Items.TheTreeSelectedPrices.Expand(TreeItem.GetID(),True);
		EndDo;
	EndIf;
		
EndProcedure	

&AtClient
Procedure DisplayAsAList(Command)
	
	TreeSelectedPricesDisplayGroups = False;
	ReFillTreeWithSelectedPrices();
	
EndProcedure

&AtClient
Procedure ToDisplayInTheTreeView(Command)
	
	TreeSelectedPricesDisplayGroups = True;
	ReFillTreeWithSelectedPrices();
	ExpandSelectedPricesTree();
	
EndProcedure


&AtClient
Procedure ExcludeAllOtherTypesOfPrices(Command)
	
	SetSelectionValuesForAllTreeElements(False);

EndProcedure

&AtClient
Procedure TheTreeSelectedRatesSelectedWhenYouChange(Item)

	CurrentData = Items.TheTreeSelectedPrices.CurrentData;
	If CurrentData.IsFolder Or Not CurrentData.Selected Then
		CurrentData.Selected = False;
		CurrentData.Edit = False;
	EndIf;

	If CurrentData.ProhibitedPriceType Then
		CurrentData.Selected_5 = False;
		CurrentData.Edit = False;
		AttachIdleHandler("InformAboutImpossibilityOfSelection", 0.2, True);
	EndIf;

	UpdateFlagsForSelectedPrices(CurrentData);

EndProcedure

&AtClient
Procedure TheTreeSelectedPricesEditOnChange(Item)
	
	CurrentData = Items.TheTreeSelectedPrices.CurrentData;
	If CurrentData.IsFolder Then
		CurrentData.Selected = False;
		CurrentData.Edit = False;
	Else
		CurrentData.Selected = CurrentData.Edit;
	EndIf;

	UpdateFlagsForSelectedPrices(CurrentData);

EndProcedure

&AtServer
Procedure SelectAllDependentTreePricesRecursively(Parent, FillIn, Tree) 
	
	For Each CurRow In Parent.Rows Do
		If Not CurRow.IsFolder Then
			If CurRow.Selected Then 	
				For Each DependentPrice In CurRow.DependentPrices Do
					DependentPriceLine = SettingPricesServer.FindPriceTypeStringInTree(Tree, DependentPrice.Value);
					If DependentPriceLine <> Undefined 
					And Not (DependentPriceLine.Selected And DependentPriceLine.Edit)
					And Not DependentPriceLine.ProhibitedPriceType Then
						DependentPriceLine.Selected = True;
						DependentPriceLine.Edit = True;
						FillIn = True;
						UpdateFlagsOfSelectedPricesOnServer(DependentPriceLine);
					EndIf;
				EndDo;
			EndIf;
		Else
			SelectAllDependentTreePricesRecursively(CurRow, FillIn, Tree);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectAllDependentPricesOnServer()
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices");
	
	FillIn = True;
	While FillIn Do
		
		FillIn = False;
		For Each CurRow In Tree.Rows Do
			If Not CurRow.IsFolder Then
				If CurRow.Selected Then 
					For Each DependentPrice In CurRow.DependentPrices Do
						DependentPriceLine = SettingPricesServer.FindPriceTypeStringInTree(Tree, DependentPrice.Value);
						If DependentPriceLine <> Undefined 
						And Not (DependentPriceLine.Selected And DependentPriceLine.Edit) 
						And Not DependentPriceLine.ProhibitedPriceType Then
							DependentPriceLine.Selected = True;
							DependentPriceLine.Edit = True;
							FillIn = True;
							UpdateFlagsOfSelectedPricesOnServer(DependentPriceLine);
						EndIf;
					EndDo;
				EndIf;
			Else
				SelectAllDependentTreePricesRecursively(CurRow, FillIn, Tree);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ValueToFormData(Tree, TheTreeSelectedPrices);
	
EndProcedure

&AtClient
Procedure SelectAllDependentPrices(Command)
	
	SelectAllDependentPricesOnServer();
	ExpandSelectedPricesTree();
	
EndProcedure


&AtServer
Procedure SelectAllInfluencingTreePricesRecursively(Parent, FillIn, Tree) 
	
	For Each CurRow In Parent.Rows Do
		If Not CurRow.IsFolder Then
			If CurRow.Selected Then 	
				For Each InfluencingPrice In CurRow.InfluencingPrices Do
					InfluencingPriceLine = SettingPricesServer.FindPriceTypeStringInTree(Tree, InfluencingPrice.Value);
					If InfluencingPriceLine <> Undefined 
					And Not (InfluencingPriceLine.Selected And InfluencingPriceLine.Edit) 
					And Not InfluencingPriceLine.ProhibitedPriceType Then
						InfluencingPriceLine.Selected = True;
						InfluencingPriceLine.Edit = True;
						FillIn = True;
						UpdateFlagsOfSelectedPricesOnServer(InfluencingPriceLine);
					EndIf;
				EndDo;
			EndIf;
		Else
			SelectAllInfluencingTreePricesRecursively(CurRow, FillIn, Tree);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectAllInfluencingPricesOnServer()
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices");
	
	FillIn = True;
	While FillIn Do
		
		FillIn = False;
		For Each CurRow In Tree.Rows Do
			If Not CurRow.IsFolder Then
				If CurRow.Selected Then
					For Each InfluencingPrice In CurRow.InfluencingPrices Do
						InfluencingPriceLine = SettingPricesServer.FindPriceTypeStringInTree(Tree, InfluencingPrice.Value);
						If InfluencingPriceLine <> Undefined 
						And Not (InfluencingPriceLine.Selected And InfluencingPriceLine.Edit) 
						And Not InfluencingPriceLine.ProhibitedPriceType Then
							InfluencingPriceLine.Selected = True;
							InfluencingPriceLine.Edit = True;
							FillIn = True;
							UpdateFlagsOfSelectedPricesOnServer(InfluencingPriceLine);
						EndIf;
					EndDo;
				EndIf;
			Else
				SelectAllInfluencingTreePricesRecursively(CurRow, FillIn, Tree);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ValueToFormData(Tree, TheTreeSelectedPrices);
	
EndProcedure


&AtClient
Procedure SelectAllInfluencingPrices(Command)
	
	SelectAllInfluencingPricesOnServer();
	ExpandSelectedPricesTree();
	
EndProcedure

&AtClient
Procedure EditSettings(Command)
	
	CurrentData = Items.TheTreeSelectedPrices.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể soạn tùy chỉnh. Chưa chọn dạng giá';
										|ru = 'Редактировать настройки невозможно. Не выбран вид цены';
										|en = 'Cannot edit settings. Price type is not selected'; fa = 'Cannot edit settings. Price type is not selected';
										|it = 'Non è possibile modificare le impostazioni. Nessun tipo di prezzo selezionato';
										|pl = 'Nie można edytować ustawień. Nie wybrano rodzaj ceny';
										|tr = 'Ayarları düzenleyemezsiniz. Fiyat türü seçilmedi'"));
		Return;
	EndIf;
	
	If Not CurrentData.Selected Then
			ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể soạn tùy chỉnh sơ đồ dàn dựng đối với các dạng giá đã chọn';
											|ru = 'Редактировать настройки схемы компоновки можно только для выбранных видов цен';
											|en = 'You can edit composition schema settings only for the selected price types'; fa = 'You can edit composition schema settings only for the selected price types';
											|it = 'È possibile modificare le impostazioni dello schema di configurazione solo per i tipi di prezzi selezionati';
											|pl = 'Można edytować ustawienia schematu układu tylko dla wybranych rodzajów cen.';
											|tr = 'Sadece seçilen fiyat türleri için inşa şeması ayarlarını düzenleyebilirsiniz'"));
		Return;
	EndIf;
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh tham số đối với dạng giá ""%1""';
													|ru = 'Настройка параметров для вида цены ""%1""';
													|en = 'Setting of parameters for kind of price ""%1""'; fa = 'Setting of parameters for kind of price ""%1""';
													|it = 'Impostazione dei parametri per il tipo di prezzo ""%1""';
													|pl = 'Ustawienie parametrów dla rodzaju ceny ""%1""';
													|tr = '""%1"" fiyat türü parametrelerinin ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", CurrentData.Description);
	
	AddressOfDataCompositionSchemaSettings = PriceSetupServerCall.AddressOfDataLayoutSettingsForPriceView(
		CurrentData.Ref,
		StorageAddressDataLayoutSettings,
		UUID);
	
	AddressOfDataCompositionSchemaSettings =
		?(AddressOfDataCompositionSchemaSettings <> Undefined,
		AddressOfDataCompositionSchemaSettings,
		CurrentData.AddressOfDataCompositionSchemaSettings);
	
	FormParameters = New Structure();
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("AddressOfDataCompositionSchema", CurrentData.AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", AddressOfDataCompositionSchemaSettings);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	
	FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", "PriceManagementSystem.CheckingCorrectnessOfPriceTypeScheme");

	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditSettingsCompletion", ThisObject, New Structure("CurrentData", CurrentData)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
// 	Result - UUID, String - 
// 	AdditionalParameters - Structure :
//	* CurrentData - Structure - Current data on price types
&AtClient
Procedure EditSettingsCompletion(Result, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;//CurrentDataOfList
	
	
	AddressOfComposerConfigurationStore = Result;
	
	If AddressOfComposerConfigurationStore <> Undefined Then
		
		StructureOfData = PriceSetupServerCall.SetDataLayoutSettingsForPriceView(
		CurrentData.Ref,
		AddressOfComposerConfigurationStore,
		StorageAddressDataLayoutSettings,
		AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
		CurrentData.Parameters = StructureOfData.ParametersDetails;
		
	EndIf;

EndProcedure

&AtClient
Procedure RestoreDefaultSettings(Command)
	
	CurrentData = Items.TheTreeSelectedPrices.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể soạn tùy chỉnh. Chưa chọn dạng giá';
										|ru = 'Редактировать настройки невозможно. Не выбран вид цены';
										|en = 'Cannot edit settings. Price type is not selected'; fa = 'Cannot edit settings. Price type is not selected';
										|it = 'Non è possibile modificare le impostazioni. Nessun tipo di prezzo selezionato';
										|pl = 'Nie można edytować ustawień. Nie wybrano rodzaj ceny';
										|tr = 'Ayarları düzenleyemezsiniz. Fiyat türü seçilmedi'"));
		Return;
	EndIf;
	
	If Not CurrentData.Selected Then
		ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể soạn tùy chỉnh sơ đồ dàn dựng đối với các dạng giá đã chọn.';
										|ru = 'Редактировать настройки схемы компоновки можно только для выбранных видов цен.';
										|en = 'You can edit composition schema settings only for the selected price types.'; fa = 'You can edit composition schema settings only for the selected price types.';
										|it = 'È possibile modificare le impostazioni dello schema di configurazione solo per i tipi di prezzi selezionati.';
										|pl = 'Można edytować ustawienia schematu układu tylko dla wybranych rodzajów cen.';
										|tr = 'Sadece seçilen fiyat türleri için inşa şeması ayarlarını düzenleyebilirsiniz.'"));
		Return;
	EndIf;
	
	AddressOfComposerConfigurationStore = PriceSetupServerCall.DefaultDataLayoutSchemeSettings(
		CurrentData.Ref, CurrentData.AddressOfDataCompositionSchema, UUID);
	
	If AddressOfComposerConfigurationStore <> Undefined Then
		StructureOfData = PriceSetupServerCall.SetDataLayoutSettingsForPriceView(
			CurrentData.Ref,
			AddressOfComposerConfigurationStore,
			StorageAddressDataLayoutSettings,
			AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
		CurrentData.Parameters = StructureOfData.ParametersDetails;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResetFiltersByProperties(Command)
	
	ResetSelectionsByPropertiesOnServer();
	
EndProcedure

#Region Other

&AtClient
Procedure InformAboutImpossibilityOfSelection()
	ClearMessages();
	CurrentData = Items.SelectedPrices.CurrentData;
	CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền đặt bảng giá theo dạng giá này';
											|ru = 'Нет прав на установку цен по данному виду цены';
											|en = 'No rights for pricing by this price type'; fa = 'No rights for pricing by this price type';
											|it = 'Nessun diritto di impostare i prezzi per questo tipo di prezzo';
											|pl = 'Brak uprawnień do ustalania cen dla tego rodzaju cen.';
											|tr = 'Bu fiyat türüne göre fiyat belirleme yetkisi yoktur'"),, "SelectedPrices[" + SelectedPrices.IndexOf(CurrentData) + "].Ref");
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure FindTreeLineRecursively(TreeOfPriceTypes, PriceTypeSearch, Id)

	For Each TreeItem In TreeOfPriceTypes.GetItems() Do
		
		If TreeItem.Ref = PriceTypeSearch Then
			Id = TreeItem.GetID();
		Else
			FindTreeLineRecursively(TreeItem, PriceTypeSearch, Id);
		EndIf; 
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateSettingsForPriceTypes(Command = Undefined)

	If Items.TheTreeSelectedPrices.CurrentData <> Undefined Then
		CurViewPrices = Items.TheTreeSelectedPrices.CurrentData.Ref;
	Else
		CurViewPrices = Undefined;
	EndIf;

	UpdateSettingsForPriceTypesOnServer();
	SelectedPricesWereChanged = (TheTreeSelectedPrices.GetItems().Count() > 0);
	
	Id = Undefined; 
	FindTreeLineRecursively(TheTreeSelectedPrices, CurViewPrices, Id);
	
	Items.TheTreeSelectedPrices.CurrentRow = Id;	
	
	ShowUserNotification(NStr("vi = 'Đã cập nhật tùy chỉnh';
								|ru = 'Настройки обновлены';
								|en = 'Settings are updated'; fa = 'Settings are updated';
								|it = 'Настройки обновлены';
								|pl = 'Settings are updated';
								|tr = 'Ayarlar güncellendi'"),, NStr("vi = 'Đã thực hiện thao tác';
																	|ru = 'Действие выполнено';
																	|en = 'Operation completed.'; fa = 'عملیات تکمیل شد.';
																	|it = 'Operazione effettuata';
																	|pl = 'Działanie zostało wykonane';
																	|tr = 'Eylem tamamlandı'"), PictureLib.Success32);
	
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesSortListAsc(Command)

	SortTreeSelectedPrices("Description");

EndProcedure

&AtClient
Procedure TheTreeSelectedPricesSortListDesc(Command)

	SortTreeSelectedPrices("Description Desc");

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFlagsForSelectedPrices(CurrentData)
	
	Var FoundRows;
	
	FoundRows =  SelectedPrices.FindRows(New Structure("Ref", CurrentData.Ref));
	If FoundRows.Count() Then
		FoundRows[0].Selected_5 = CurrentData.Selected;
		FoundRows[0].Edit = CurrentData.Edit;
	EndIf;
	
EndProcedure

// Update the flags of the selected prices on the server.
// 
// Parameters:
//  CurrentData - See SettingPricesServer.FindPriceTypeStringInTree
&AtServer
Procedure UpdateFlagsOfSelectedPricesOnServer(CurrentData)
	
	Var FoundRows;
	
	FoundRows =  SelectedPrices.FindRows(New Structure("Ref", CurrentData.Ref));
	If FoundRows.Count() Then
		FoundRows[0].Selected_5 = CurrentData.Selected;
		FoundRows[0].Edit = CurrentData.Edit;
	EndIf;
	
EndProcedure


&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

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
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSelectedPricesEdit.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSelectedPricesSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheTreeSelectedPrices.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly",True); 

EndProcedure

&AtClient
Procedure TheTreeSelectedPricesOnActivateRow(Item)
	InfoString = CurLineInformation();
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesValueChoice(Item, Value, StandardProcessing)
	StandardProcessing = False;
EndProcedure


&AtClient
//The function of the information of the running line(Elements,
//	                            Selected Tokens,
//	                            Current price datesreferences,
//	                            Current Date,
//	                            Use the characteristics of the nomenclature,
//	                            Not using formulas = Lies) 
Function CurLineInformation() 
	
	
	CurrentData = Items.TheTreeSelectedPrices.CurrentData;
	If CurrentData = Undefined Then
		Return "";
	EndIf;
	
	DateOfTheLastPriceSetting = Format(CurrentData.DateOfTheLastPriceSetting,"DLF=D;");
	
	If CurrentData.DateOfTheLastPriceSetting > Date Then
		StringInformation_ = StrTemplate(NStr("vi = 'Theo dạng giá %1 đã đặt đơn giá - %2';
												|ru = 'По виду цен %1 цена установлена - %2';
												|en = 'By the %1 price type, the price is set - %2'; fa = 'By the %1 price type, the price is set - %2';
												|it = 'Per il tipo di prezzo %1 è impostato il prezzo - %2';
												|pl = 'Wg rodzaju cen %1 jest ustalona cena - %2';
												|tr = '%1 fiyat türüne göre fiyat yapılandırıldı; %2'"), CurrentData.Ref, DateOfTheLastPriceSetting);
	ElsIf Not ValueIsFilled(CurrentData.DateOfTheLastPriceSetting) Then 
		StringInformation_ = StrTemplate(NStr("vi = 'Theo dạng giá %1 chưa đặt bảng giá.';
												|ru = 'По виду цен %1 не было установок цен.';
												|en = 'There was no pricing by the %1 price type.'; fa = 'There was no pricing by the %1 price type.';
												|it = 'Per il tipo di prezzo %1 non vi è stata impostazione del prezzo.';
												|pl = 'Wg rodzaju cen %1 nie ustalono cen.';
												|tr = '%1 fiyat türüne göre fiyat yapılandırması yapılmadı.'"), CurrentData.Ref);
	Else
		StringInformation_ = StrTemplate(NStr("vi = 'Theo dạng giá %1, đơn giá đã đặt gần nhất %2.';
												|ru = 'По виду цен %1 последняя цена установлена %2.';
												|en = 'By the %1 price type the last price is set %2.'; fa = 'By the %1 price type the last price is set %2.';
												|it = 'Per il tipo di prezzo %1 l''ultimo prezzo impostato è %2.';
												|pl = 'Wg rodzaju cen %1 jest ustalona ostatnia cena %2.';
												|tr = '%1 fiyat türüne göre yapılandırılan son fiyat %2.'"), CurrentData.Ref, DateOfTheLastPriceSetting);
	EndIf;

	FormattedStringPriceView = New FormattedString(StringInformation_);
	
	Return FormattedStringPriceView;
	
EndFunction

&AtServer
Procedure NavigationOptionWhenChangingOnServer()
	
	SelectGoodsServer.SetNavigationOptionPage(ThisObject);
	
	Items.ProductKind.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties);
	Items.ResetFiltersByProperties.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties);
	
	Items.CommandBarOfProductList.Visible = (NavigationOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives);
	
EndProcedure

&AtServer
Procedure ProductKindOnChangeServer()

	SelectGoodsServer.FillInProductSelectionTree(ThisObject);
	
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
	
	SelectGoodsServer.ResetFiltersByProperties(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FindSelectionLines(SelectionTreeString, ItemArray)
	
	RowsArray = SelectionTreeString.GetItems();
	For Each String In RowsArray Do
		If String.Filter Then
			ItemArray.Add(String);
		EndIf;
		FindSelectionLines(String, ItemArray);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeForm(Form)
	
	SimplifiedSetting = (Form.SettingKind = "Basic");
	
	If SimplifiedSetting Then
		Form.Items.FilterOptions.CurrentPage = Form.Items.FilterOptions.ChildItems.Basic;
	Else
		Form.Items.FilterOptions.CurrentPage = Form.Items.FilterOptions.ChildItems.Advanced;
	EndIf;
	
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
		
		SettingPricesClientServer.MarkRecursivelyUpwards(TopLevelLines);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form)
	
	
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
	
	SelectionValues = New ValueList;
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
	SelectGoodsServer.SetNavigationOptionPage(ThisObject);
	
	// Set the type of nomenclature and fill in the selection tree.
	Form.ProductKind = Common.ObjectAttributeValue(Products, "ProductKind");
	SelectGoodsServer.FillInProductSelectionTree(ThisObject);
	
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
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ComposerSettings", SettingsComposerFilter.Settings);
	StructureOfData.Insert("ColumnComposerSettings", SettingsBuilderColumnSelection.Settings);
	StructureOfData.Insert("SelectedPrices", SelectedPrices.Unload());
	StructureOfData.Insert("Date", EndOfDay(Date));
	StructureOfData.Insert("SettingKind", SettingKind);
	StructureOfData.Insert("NavigationOption",NavigationOption);
	StructureOfData.Insert("ProductKind",ProductKind);
	StructureOfData.Insert("FilterParametersTable", FilterParametersTable.Unload());
	StructureOfData.Insert("GroupingOption",GroupingOption);
	StructureOfData.Insert("OptionForSettingThePrice",OptionForSettingThePrice);
	StructureOfData.Insert("PriceSettingOption",PriceSettingOption);
	StructureOfData.Insert("AvailabilityOption",AvailabilityOption);
	
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
	SimplifiedSetting.Insert("PriceIsSet",  Undefined);
	SimplifiedSetting.Insert("TypeOfPriceSelection", Undefined);
	SimplifiedSetting.Insert("ProductGroups", Undefined);
	SimplifiedSetting.Insert("Products", Undefined);
	SimplifiedSetting.Insert("MarketingActivity",Undefined);
	SimplifiedSetting.Insert("AvailabilityWarehouse", Undefined);
	SimplifiedSetting.Insert("PriceSettingOption",3);
	SimplifiedSetting.Insert("AvailabilityOption",3);
	
	ProductSegmentField  = New DataCompositionField("ProductSegment");
	PriceFromField               = New DataCompositionField("PriceFrom");
	PriceBeforeField               = New DataCompositionField("PriceUpTo");
	FieldBalance              = New DataCompositionField("Balance");
	SalesAllowedField     = New DataCompositionField("SalesAllowed");
	ProductsField         = New DataCompositionField("Products");
	ParentProductField = New DataCompositionField("Products.Parent");
	PlanningObjectField   = New DataCompositionField("PlanningObject");
	PriceViewRangeField      = New DataCompositionField("PriceTypeRange");
	FieldMarketingEvent = New DataCompositionField("MarketingActivity");
	WarehouseAvailabilityField = New DataCompositionField("Warehouse");
	FieldIsOnlyAvailable = New DataCompositionField("OnlyInStock");
	PriceFieldIsSet     = New DataCompositionField("PriceIsSet"); 
	
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
		
		If String(FilterElement.LeftValue) = String(FieldIsOnlyAvailable)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use Then
				
				If FilterElement.RightValue = True Then
					SimplifiedSetting.AvailabilityOption = 1;
				Else
					SimplifiedSetting.AvailabilityOption = 2;
				EndIf;
				
			Else
				SimplifiedSetting.AvailabilityOption = 3;
			EndIf;
			
			Continue;
			
		EndIf;
		
		If String(FilterElement.LeftValue) = String(WarehouseAvailabilityField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use And SimplifiedSetting.AvailabilityWarehouse = Undefined  Then
				SimplifiedSetting.AvailabilityWarehouse = FilterElement.RightValue;
				SimplifiedSetting.AvailabilityOption = 1;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.AvailabilityWarehouse <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(FieldMarketingEvent)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			
			If FilterElement.Use And SimplifiedSetting.MarketingActivity = Undefined  Then
				SimplifiedSetting.MarketingActivity = FilterElement.RightValue;
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.MarketingActivity <> Undefined);
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
		
		If String(FilterElement.LeftValue) = String(FieldBalance) Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.Greater
				And FilterElement.RightValue = 0 Then
				
				If FilterElement.Use Then
					SimplifiedSetting.AvailabilityOption = 1;
				EndIf;
				
			EndIf;
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(PriceFieldIsSet)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.RightValue = True Then
	
			If FilterElement.Use Then
				SimplifiedSetting.PriceSettingOption = 1;
			EndIf;
		ElsIf String(FilterElement.LeftValue) = String(PriceFieldIsSet)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.RightValue = False Then
	
			If FilterElement.Use Then
				SimplifiedSetting.PriceSettingOption = 2;
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
		
		If String(FilterElement.LeftValue) = String(ParentProductField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.ProductGroups = Undefined  Then
				SimplifiedSetting.ProductGroups = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.ProductGroups <> Undefined);
			EndIf;
			
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) = String(ProductsField)
			And FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			
			If FilterElement.Use And SimplifiedSetting.Products = Undefined  Then
				SimplifiedSetting.Products = FilterElement.RightValue.UnloadValues();
			Else
				SimplifiedSetting.SettingsWillBeLost = (SimplifiedSetting.Products <> Undefined);
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
	
	If ValueIsFilled(Form.MarketingActivity) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"MarketingActivity",
			DataCompositionComparisonType.Equal,
			Form.MarketingActivity,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
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
	
	If Form.AvailabilityOption = 1 Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"OnlyInStock",
			DataCompositionComparisonType.Equal,
			True,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	ElsIf Form.AvailabilityOption = 2 Then
			
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"OnlyInStock",
			DataCompositionComparisonType.Equal,
			False,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
		SelectionByAbsenceOfResidue = CommonClientServer.CreateFilterItemGroup(
			Form.SettingsComposerFilter.Settings.Filter.Items,
			NStr("vi = 'Lọc không có số dư';
				|ru = 'Отбор отсутствию остатка';
				|en = 'Filter by balance absence'; fa = 'Filter by balance absence';
				|it = 'Filtro per mancanza di saldo';
				|pl = 'Filtr braku salda';
				|tr = 'Bakiye yokluğu filtresi'"),
			DataCompositionFilterItemsGroupType.OrGroup);	
			
		CommonClientServer.AddCompositionItem(
			SelectionByAbsenceOfResidue,
			"Balance",
			DataCompositionComparisonType.Equal,
			0,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
		CommonClientServer.AddCompositionItem(
			SelectionByAbsenceOfResidue,
			"Balance",
			DataCompositionComparisonType.NotFilled,
			,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
	If Form.PriceSettingOption <> 3 Then
		
		CommonClientServer.AddCompositionItem(
		Form.SettingsComposerFilter.Settings.Filter,
		"PriceIsSet",
		DataCompositionComparisonType.Equal,
		(Form.PriceSettingOption = 1),
		Undefined,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
		
		// set a limit on the type of prices
		ListOfSelectedPriceTypes = New ValueList();
		For Each PriceViewString In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			ListOfSelectedPriceTypes.Add(PriceViewString.Ref);
		EndDo;
		
		FilterElement = CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PriceTypeRange",
			DataCompositionComparisonType.InList,
			ListOfSelectedPriceTypes,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
//		Element selection.Application = Type of application of data collection.Hierarchy;
		
	EndIf;
		
	If ValueIsFilled(Form.TypeOfPriceSelection) Then
		
		FilterElement = CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"PriceTypeRange",
			DataCompositionComparisonType.Equal,
			Form.TypeOfPriceSelection,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
		FilterElement.Application = DataCompositionFilterApplicationType.Hierarchy;
		
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
	
	If ValueIsFilled(Form.AvailabilityWarehouse) Then
		
		CommonClientServer.AddCompositionItem(
			Form.SettingsComposerFilter.Settings.Filter,
			"Warehouse",
			DataCompositionComparisonType.Equal,
			Form.AvailabilityWarehouse,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
		

EndProcedure

&AtClient
Procedure TypeOfPriceSelectionOnChange(Item)
	AutoTagBlankContent(ThisObject);
EndProcedure

// Set up auto-tagging of blank.
// 
// Parameters:
//  Form - ClientApplicationForm
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
Function FillInTreeOfPriceTypes(TableOfSelectedPrices)
	Var Tree;
	
	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED
	|	TypesOfPrices.Ref AS Ref,
	|	TypesOfPrices.Parent AS Parent,
	|	TypesOfPrices.Description AS Description,
	|	TypesOfPrices.IsFolder AS IsFolder,
	|	TypesOfPrices.PriceCurrency AS Currency,
	|	FALSE AS Selected,
	|	FALSE AS Edit,
	|	CASE
	|		WHEN TypesOfPrices.IsFolder
	|			THEN 0
	|		ELSE 2
	|	END AS Picture,
	|	CASE
	|		WHEN TypesOfPrices.IsFolder
	|			THEN DATETIME(1, 1, 1, 0, 0, 0)
	|		ELSE ISNULL(DatesOfLastPriceSettings.Period, DATETIME(1, 1, 1, 0, 0, 0))
	|	END AS DateOfTheLastPriceSetting
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|		LEFT JOIN (SELECT
	|			ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
	|			MAX(ItemPricesCrossSectionOfTheLatest.Period) AS Period
	|		FROM
	|			InformationRegister.ItemsPrices.SliceLast AS ItemPricesCrossSectionOfTheLatest
	|		GROUP BY
	|			ItemPricesCrossSectionOfTheLatest.PriceKind) AS DatesOfLastPriceSettings
	|		ON DatesOfLastPriceSettings.PriceKind = TypesOfPrices.Ref
	|WHERE
	|	CASE
	|		WHEN TypesOfPrices.IsFolder
	|			THEN TRUE
	|		ELSE TypesOfPrices.Ref IN (&ArrayOfSelectedStrings)
	|	END";
	
	If UsePriceManagementSystem25 Then
		Query.Text = StrReplace(Query.Text, "InformationRegister.ItemsPrices", "InformationRegister.ItemsPrices25");
	EndIf;
	
	ArrayOfSelectedStrings = New Array;
	For Each Page1 In TableOfSelectedPrices Do
		If TheTreeSelectedPricesDisplayOnlySelectedItems And Page1.Selected_5 Or Not TheTreeSelectedPricesDisplayOnlySelectedItems Then
			ArrayOfSelectedStrings.Add(Page1.Ref);
		EndIf;
	EndDo;
	Query.Parameters.Insert("ArrayOfSelectedStrings",ArrayOfSelectedStrings);		
	
	If TreeSelectedPricesDisplayGroups And Not TheTreeSelectedPricesDisplayOnlySelectedItems Then
		
		Query.Text = Query.Text+"
		|ORDER BY
		|	Ref HIERARCHY";
		
	Else
		
		Query.Text = Query.Text+"
		|AND
		|	NOT TypesOfPrices.IsFolder ";
		
	EndIf;
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));
	Tree.Rows.Clear();
	NewRow = Tree;
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	BuildHierarchyOfProducts(Result.Rows, NewRow);
	
	For Each TreeItem In Tree.Rows Do
		If Not TreeItem.IsFolder Then
			TableRow = TableOfSelectedPrices.Find(TreeItem.Ref,"Ref");
			If TableRow <> Undefined Then
				FillPropertyValues(TreeItem,TableRow);
				TreeItem.Selected = TableRow.Selected_5;
			EndIf;
		Else 
			SettingPricesClientServer.FillInPropertyValuesRecursively(TreeItem,TableOfSelectedPrices);
		EndIf;
	EndDo;
	
	Return Tree;
EndFunction

&AtClient
Procedure SetColumnLayoutParameters()
	
	OtherTypesOfPrices = New Array();
	For Each CurRow In SelectedPrices Do
		If CurRow.Selected_5 Then
			OtherTypesOfPrices.Add(CurRow.Ref);
		EndIf;
	EndDo;
	ListOfSelectedPrices = New ValueList;
	ListOfSelectedPrices.LoadValues(OtherTypesOfPrices);
	ParameterValue = SettingsBuilderColumnSelection.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("ListOfPriceTypes"));
	ParameterValue.Value = ListOfSelectedPrices;
	ParameterValue.Use = True;  
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	Items.InfoString.Visible = False;
	Items.SettingKind.Visible = False;			
	
	If CurrentPage.Name = "Filters" Then
		Items.SettingKind.Visible = True;
	EndIf;
	
	If CurrentPage.Name = "SelectionOfPriceTypes_3" Then
		Items.InfoString.Visible = True;
	EndIf;
	
	SetColumnLayoutParameters();
	
EndProcedure

&AtClient
Procedure AvailabilityOptionOnChange(Item)

	If AvailabilityOption = 3 Then
		AvailabilityWarehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");	
	EndIf;

	WhenChangingAvailabilityOption();

EndProcedure

&AtClient
Procedure WhenChangingAvailabilityOption()

	CommonClientServer.SetFormItemProperty(Items, "AvailabilityWarehouse", "Enabled", AvailabilityOption <> 3);

EndProcedure

&AtClient
Procedure AvailabilityWarehouseOnChange(Item)
	
	If AvailabilityOption = 3 And ValueIsFilled(AvailabilityWarehouse) Then
		AvailabilityWarehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");	
		Message(NStr("vi = 'Hãy chỉ ra phương án lọc khác khi có hàng hóa. Không thể chọn kho đối với phương án [Không quan trọng].';
					|ru = 'Укажите другой вариант отбора по наличию товаров. Для варианта [Не важно] выбрать склад нельзя.';
					|en = 'Specify another filter option based on the availability of goods items. You cannot select a warehouse for the [Doesn''t matter] option.'; fa = 'Specify another filter option based on the availability of goods items. You cannot select a warehouse for the [Doesn''t matter] option.';
					|it = 'Indicare un''altra variante di filtro per disponibilità dei prodotti. Per la variante [non importante] non deve essere selezionato il magazzino.';
					|pl = 'Podaj inny wariant filtru wg dostępności towarów. Dla wariantu [Nie ważne] nie można wybrać magazynu.';
					|tr = 'Ürünlerin mevcudiyetine göre başka bir filtre seçeneği belirtin. [Önemli değil] seçeneği için ambar seçemezsiniz.'"))
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateSettingsForPriceTypesOnServer()
	
	RowsSelected = New Map;
	For Each StringOfPriceTypes In SelectedPrices Do
		
		If StringOfPriceTypes.Selected_5
			Or StringOfPriceTypes.Edit Then
			
			RowsSelected.Insert(StringOfPriceTypes.Ref,
				New Structure("Selected_5, Edit",
				StringOfPriceTypes.Selected_5, StringOfPriceTypes.Edit)
			);
			
		EndIf;
			
	EndDo;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	For Each StringOfPriceTypes In SelectedPrices Do
		
		ColumnValues = RowsSelected.Get(StringOfPriceTypes.Ref);
		If ColumnValues <> Undefined Then
			FillPropertyValues(StringOfPriceTypes, ColumnValues);
		EndIf;
		
	EndDo;
	
	Tree = FillInTreeOfPriceTypes(SelectedPrices.Unload());
	ValueToFormData(Tree, TheTreeSelectedPrices);

EndProcedure

&AtServer
Procedure SortTreeSelectedPrices(ColumnsList)

	TreeObject = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));
	TreeObject.Rows.Sort(ColumnsList);
	ValueToFormAttribute(TreeObject, "TheTreeSelectedPrices");

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
