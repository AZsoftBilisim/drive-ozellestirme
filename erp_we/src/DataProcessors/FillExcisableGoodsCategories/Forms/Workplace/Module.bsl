#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	CurrentSessionDate = CurrentSessionDate();
	
	Country = SettingsValueClientServerCached.MainCountry();
	Period = CurrentSessionDate;
	
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Country", Country);
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Period", ?(Not ValueIsFilled(Period), CurrentSessionDate, EndOfDay(Period)));
		
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ItemList);
	
	ListProperties.QueryText = StrReplace(ItemList.QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CategoriesOverridable.ExcisableGoodsCategory.UnitOfMeasure",
			"ProductsOverridable.Ref"));
		
	Common.SetDynamicListProperties(Items.ItemList, ListProperties);
	
	UpdateInformationByCategory();
	UpdateListOfCategories();
	
	ExcisableGoods = 0;
	MultiCountryAccounting = GetFunctionalOption("UseMultiCountryAccounting");
	
	Items.ConversionRatioSelection.ChoiceList.Clear();
	Items.ConversionRatioSelection.ChoiceList.Add("<All>", NStr("vi = '<Bất kỳ>';
																|ru = '<Любой>';
																|en = '<Any>'; fa = '<هر>';
																|it = '<Any>';
																|pl = '<Any>';
																|tr = '<Herhangi>'"));
	Items.ConversionRatioSelection.ChoiceList.Add("<Specified>", NStr("vi = '<Đã chỉ định>';
																		|ru = '<Указан>';
																		|en = '<Specified>'; fa = '<Specified>';
																		|it = '<Specified>';
																		|pl = '<Specified>';
																		|tr = '<Belirtildi>'"));
	Items.ConversionRatioSelection.ChoiceList.Add("<Not specified>", NStr("vi = '<Chưa chỉ ra>';
																			|ru = '<Не указан>';
																			|en = '<not specified>'; fa = '<مشخص نشده>';
																			|it = '<non specificato>';
																			|pl = '<Nie określono>';
																			|tr = '<Belirtilmedi>'"));
	Items.ConversionRatioSelection.ChoiceList.Add("<Select>", NStr("vi = '<Chỉ định hệ số...>';
																	|ru = '<Указать коэффициент...>';
																	|en = '<Specify the ratio...>'; fa = '<Specify the ratio...>';
																	|it = '<Specify the ratio...>';
																	|pl = '<Specify the ratio...>';
																	|tr = '<Katsayı belirt...>'"));
	ConversionRatioSelection = "<All>";
	ConversionRatioSelectionTo = ConversionRatioSelection;
	
	SetFilterByFlag();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Country", Country);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Products" Then
		UpdateInformationByCategory();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Period", EndOfDay(Period));
	UpdateInformationByCategory();
	
EndProcedure

&AtClient
Procedure CountryOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Country", Country);
	UpdateInformationByCategory();
	UpdateListOfCategories();
	
EndProcedure

&AtClient
Procedure ExcisableGoodsOnChange(Item)
	
	SetFilterByFlag();
	
EndProcedure

&AtClient
Procedure SelectionCategoryOnChange(Item)
	
	If Not ValueIsFilled(SelectionCategory) Then
		SelectionCategory = 0;
	EndIf;
	
	If SelectionCategory = 3 Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Country", Country);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterParameters);
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("MultipleChoice", False);
		
		OpenForm("Catalog.ExcisableGoodsCategories.ChoiceForm", FormParameters,
			ThisObject, , , ,New CallbackDescription("SelectionOfExciseCategoryEnd", ThisObject));
	Else
		SetFilterByFlag();
		SelectionCategoryUpTo = SelectionCategory;
	EndIf;
	
EndProcedure

&AtClient
Procedure DestinationCategoryOnChange(Item)
	
	SetTypeOfExciseUnit();
	
EndProcedure

&AtClient
Procedure ConversionRatioSelectionOnChange(Item)
	
	If TypeOf(ConversionRatioSelection) = Type("String")
		And ConversionRatioSelection = "<Select>" Then
		ToRequestCoefficient(Undefined);
	Else
		If Not ValueIsFilled(ConversionRatioSelection) Then
			ConversionRatioSelection = "<All>";
		EndIf;
		SetFilterByFlag();
		ConversionRatioSelectionTo = ConversionRatioSelection;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetExciseCategoryOfItemForCurrentSelection(Command)
	
	ClearMessages();
	If CheckFillingParameters(True) Then
		Return;
	EndIf;
	
	DataByChange = FillInDataForChangingItem(True);
	
	If DataByChange.ListAddress = Undefined Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách không có hàng hóa.';
								|ru = 'В списке нет товара.';
								|en = 'There are no goods in the list.'; fa = 'There are no goods in the list.';
								|it = 'There are no goods in the list.';
								|pl = 'There are no goods in the list.';
								|tr = 'Listede ürün yok.'"));
		Return;
	EndIf;
	
	DataByChange.Insert("ExcisableGoodsCategory", DestinationCategory);
	DataByChange.Insert("Period", Period);
	DataByChange.Insert("Country", Country);
	
	If DataByChange.ThereIsAlreadyEstablishedCategory Then
		
		If MultiCountryAccounting Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có các thể loại hàng hóa chịu thuế tiêu thụ đặc biệt đang có hiệu lực. Đặt thể loại ""%1"" cho hàng hóa trong danh sách theo quốc gia %2 từ %3?';
					|ru = 'Уже есть действующие подакцизные категории. Установить категорию ""%1"" для товара из списка по стране %2 с %3?';
					|en = 'There are already active excise categories. Set the ""%1"" category for the product from the list for the ""%2"" country from %3?'; fa = 'There are already active excise categories. Set the ""%1"" category for the product from the list for the ""%2"" country from %3?';
					|it = 'There are already active excise categories. Set the ""%1"" category for the product from the list for the ""%2"" country from %3?';
					|pl = 'There are already active excise categories. Set the ""%1"" category for the product from the list for the ""%2"" country from %3?';
					|tr = 'Halihazırda geçerli olan tüketim vergisine tabi kategoriler bulunmaktadır. %3 olan %2 ülke kapsamında listedeki ürün için ""%1"" kategorisi ayarlansın mı?'"),
				DestinationCategory,
				Country,
				Format(Period,"DLF=D"));
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có các thể loại hàng hóa chịu thuế tiêu thụ đặc biệt đang có hiệu lực. Đặt thể loại ""%1"" cho hàng hóa trong danh sách từ %2?';
					|ru = 'Уже есть действующие подакцизные категории. Установить категорию ""%1"" для товара из списка с %2?';
					|en = 'There are already active excise categories. Set the ""%1"" category for the item from the list from %2?'; fa = 'There are already active excise categories. Set the ""%1"" category for the item from the list from %2?';
					|it = 'There are already active excise categories. Set the ""%1"" category for the item from the list from %2?';
					|pl = 'There are already active excise categories. Set the ""%1"" category for the item from the list from %2?';
					|tr = 'Halihazırda geçerli olan tüketim vergisine tabi kategoriler bulunmaktadır. %2 olan listedeki ürün için ""%1"" kategorisi ayarlansın mı?'"),
				DestinationCategory,
				Format(Period,"DLF=D"));
		EndIf;
		
		ShowQueryBox(New CallbackDescription("SetExciseCategoryOfItemCompletion", ThisObject, DataByChange),
			QueryText,
			QuestionDialogMode.YesNo);
			
	Else
		SetExciseCategoryOfItemOnClient(DataByChange);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetExciseCategoryOfItemAccordingToSelectedLines(Command)
	
	ClearMessages();
	SelectedRows = Items.ItemList.SelectedRows;

	If CheckFillingParameters(True) Then
		Return;
	EndIf;
	
	ItemToChange = New Array;
	ThereIsAlreadyEstablishedCategory = False;
	For Each Item In SelectedRows Do
		CurrentRow = Items.ItemList.RowData(Item);
		If CurrentRow.IsFolder Then
			Continue;
		EndIf;
		If ValueIsFilled(CurrentRow.ExcisableGoodsCategory) Then
			ThereIsAlreadyEstablishedCategory = True;
		EndIf;
		If ItemToChange.Find(CurrentRow.Ref) = Undefined Then
			ItemToChange.Add(CurrentRow.Ref);
		EndIf;
	EndDo;

	If ItemToChange.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Để tiếp tục, cần chọn các dòng.';
								|ru = 'Для продолжения необходимо выделить строки.';
								|en = 'To continue, select lines.'; fa = 'To continue, select lines.';
								|it = 'To continue, select lines.';
								|pl = 'To continue, select lines.';
								|tr = 'Devam etmek için satırları seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	DataByChange = New Structure();
	DataByChange.Insert("ListAddress", Undefined);
	DataByChange.Insert("ItemList", ItemToChange);
	DataByChange.Insert("ExcisableGoodsCategory", DestinationCategory);
	DataByChange.Insert("Period", Period);
	DataByChange.Insert("Country", Country);
	
	If ThereIsAlreadyEstablishedCategory Then
		
		If MultiCountryAccounting Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có các thể loại hàng hóa chịu thuế tiêu thụ đặc biệt đang có hiệu lực. Đặt thể loại ""%1"" cho hàng hóa đã chọn theo quốc gia %2 từ %3?';
					|ru = 'Уже есть действующие подакцизные категории. Установить категорию ""%1"" для выделенного товара по стране %2 с %3?';
					|en = 'There are already active excise categories. Set the ""%1"" category for the selected product for the ""%2"" country from %3?'; fa = 'There are already active excise categories. Set the ""%1"" category for the selected product for the ""%2"" country from %3?';
					|it = 'There are already active excise categories. Set the ""%1"" category for the selected product for the ""%2"" country from %3?';
					|pl = 'There are already active excise categories. Set the ""%1"" category for the selected product for the ""%2"" country from %3?';
					|tr = 'Halihazırda geçerli olan tüketim vergisine tabi kategoriler bulunmaktadır. %3 olan %2 ülke kapsamında seçili ürün için ""%1"" kategorisi ayarlansın mı?'"),
				DestinationCategory,
				Country,
				Format(Period,"DLF=D"));
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có các thể loại hàng hóa chịu thuế tiêu thụ đặc biệt. Đặt thể loại ""%1"" cho hàng hóa đã chọn từ %2?';
					|ru = 'Уже есть действующие подакцизные категории. Установить категорию ""%1"" для выделенного товара с %2?';
					|en = 'There are already active excise categories. Set the ""%1"" category for the selected item from %2?'; fa = 'There are already active excise categories. Set the ""%1"" category for the selected item from %2?';
					|it = 'There are already active excise categories. Set the ""%1"" category for the selected item from %2?';
					|pl = 'There are already active excise categories. Set the ""%1"" category for the selected item from %2?';
					|tr = 'Halihazırda geçerli olan tüketim vergisine tabi kategoriler bulunmaktadır. %2 olan seçili ürün için ""%1"" kategorisi ayarlansın mı?'"),
				DestinationCategory,
				Format(Period,"DLF=D"));
		EndIf;
		
		ShowQueryBox(New CallbackDescription("SetExciseCategoryOfItemCompletion", ThisObject, DataByChange),
			QueryText,
			QuestionDialogMode.YesNo);
			
	Else
		SetExciseCategoryOfItemOnClient(DataByChange);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCoefficientForSelectedLines(Command)
	
	ClearMessages();
	If CheckFillingParameters(False) Then
		Return;
	EndIf;
	
	SelectedRows = Items.ItemList.SelectedRows;
		
	ItemToChange = New Array;
	ThereAreItemsWithoutCategory = False;
	AutocompletionOfConversionRatio = False;
	RequestCoefficient = False; 
	ThereAreDifferentUnits = False;
	UnitOfProductMeasurement_ = Undefined;
	ThereIsAdValoremRate = False;
	CategoryUnitOfMeasurement = Undefined;
	ThereAreDifferentUnitsOfCategory = False;
	
	For Each Item In SelectedRows Do
		CurrentRow = Items.ItemList.RowData(Item);
		If CurrentRow.IsFolder Then
			Continue;
		EndIf;
		If Not ValueIsFilled(CurrentRow.ExcisableGoodsCategory) Then
			ThereAreItemsWithoutCategory = True;
			Break;
		EndIf;
		If Not CurrentRow.ItSFirmBet Then
			ThereIsAdValoremRate = True;
			Break;
		EndIf;
		
		If CategoryUnitOfMeasurement = Undefined Then
			CategoryUnitOfMeasurement = CurrentRow.CategoryUnit;
		ElsIf CategoryUnitOfMeasurement <> CurrentRow.CategoryUnit Then
			ThereAreDifferentUnitsOfCategory = True;
			Break;
		EndIf;
		
		If CurrentRow.AutocompletionOfConversionRatio Then
		    AutocompletionOfConversionRatio = True;
		Else
			RequestCoefficient = True;
		EndIf;
		If UnitOfProductMeasurement_ = Undefined Then
			UnitOfProductMeasurement_ = CurrentRow.UnitOfMeasure;
		EndIf;
		If Not ThereAreDifferentUnits
			And CurrentRow.UnitOfMeasure <> UnitOfProductMeasurement_ Then
			ThereAreDifferentUnits = True;
		EndIf;
		ItemToChange.Add(New Structure("Products, ExcisableGoodsCategory, AutoConversionRatio",
			CurrentRow.Ref, CurrentRow.ExcisableGoodsCategory, CurrentRow.AutoConversionRatio));
	EndDo;

	CoefficientFillingParameters = New Structure;
	CoefficientFillingParameters.Insert("ListAddress", Undefined);
	CoefficientFillingParameters.Insert("Period", Period);
	CoefficientFillingParameters.Insert("Country", Country);	
	CoefficientFillingParameters.Insert("ItemList", ItemToChange);
	CoefficientFillingParameters.Insert("AutocompletionOfConversionRatio", AutocompletionOfConversionRatio);
	CoefficientFillingParameters.Insert("RequestCoefficient", RequestCoefficient);
	CoefficientFillingParameters.Insert("ThereAreDifferentUnits", ThereAreDifferentUnits);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AutocompletionOfConversionRatio", AutocompletionOfConversionRatio);
	OpeningParameters.Insert("RequestCoefficient", RequestCoefficient);
	OpeningParameters.Insert("ThereAreDifferentUnits", ThereAreDifferentUnits);
	OpeningParameters.Insert("CategoryUnitOfMeasurement", CategoryUnitOfMeasurement);
	
	If Not DisplayWarningWhenSettingCoefficient(ThereAreItemsWithoutCategory,
			ThereIsAdValoremRate,
			AutocompletionOfConversionRatio And RequestCoefficient,
			ThereAreDifferentUnitsOfCategory,
			ItemToChange.Count() = 0) Then
		OpenForm("InformationRegister.ExcisableGoodsCategories.Form.RatioSettingParameters", OpeningParameters,,,,,
			New CallbackDescription("SettingEndFactor", ThisObject, CoefficientFillingParameters),);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCoefficientForCurrentSelection(Command)
	
	ClearMessages();	
	If CheckFillingParameters(False) Then
		Return;
	EndIf;
	
	CoefficientFillingParameters = GetParametersForRecalculatingCoefficient();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AutocompletionOfConversionRatio", CoefficientFillingParameters.AutocompletionOfConversionRatio);
	OpeningParameters.Insert("RequestCoefficient", CoefficientFillingParameters.RequestCoefficient);
	OpeningParameters.Insert("ThereAreDifferentUnits", CoefficientFillingParameters.ThereAreDifferentUnits);
	OpeningParameters.Insert("CategoryUnitOfMeasurement", CoefficientFillingParameters.CategoryUnitOfMeasurement);
	OpeningParameters.Insert("ListAddress", CoefficientFillingParameters.ListAddress);
	
	If Not DisplayWarningWhenSettingCoefficient(CoefficientFillingParameters.ThereAreItemsWithoutCategory,
			CoefficientFillingParameters.ThereIsAdValoremRate,
			CoefficientFillingParameters.AutocompletionOfConversionRatio And CoefficientFillingParameters.RequestCoefficient,
			CoefficientFillingParameters.ThereAreDifferentUnitsOfCategory,
			CoefficientFillingParameters.ListAddress = Undefined) Then
		OpenForm("InformationRegister.ExcisableGoodsCategories.Form.RatioSettingParameters", OpeningParameters,,,,,
			New CallbackDescription("SettingEndFactor", ThisObject, CoefficientFillingParameters),);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearExcisableAttributeOnSelectedLines(Command)
	
	ClearMessages();
	
	SelectedRows = Items.ItemList.SelectedRows;
	If SelectedRows.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Để tiếp tục, cần tách dòng';
										|ru = 'Для продолжения необходимо выделить строки';
										|en = 'Select lines to continue'; fa = 'Select lines to continue';
										|it = 'Per continuare è necessario evidenziare le righe';
										|pl = 'Aby kontynuować należy wybrać wiersze';
										|tr = 'Devam etmek için satırları seçin'"));
		Return;
	EndIf;
	
	If CheckFillingParameters(False) Then
		Return;
	EndIf;

	ItemToChange = New Array;
	For Each Item In SelectedRows Do
		CurrentRow = Items.ItemList.RowData(Item);
		If CurrentRow.IsFolder Then
			Continue;
		EndIf;
		If Not CurrentRow.ExcisableGoods Then
			Continue;
		EndIf;
		If ItemToChange.Find(CurrentRow.Ref) = Undefined Then
			ItemToChange.Add(CurrentRow.Ref);
		EndIf;
	EndDo;
	
	If ItemToChange.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Để tiếp tục, cần chọn các dòng có mặt hàng chịu thuế tiêu thụ đặc biệt.';
										|ru = 'Для продолжения необходимо выделить строки с подакцизной номенклатурой.';
										|en = 'To continue, select lines with excisable items.'; fa = 'To continue, select lines with excisable items.';
										|it = 'To continue, select lines with excisable items.';
										|pl = 'To continue, select lines with excisable items.';
										|tr = 'Devam etmek için, tüketim vergisine tabi öğenin olduğu satırları seçmeniz gerekmektedir.'"));
	Else
		
		DataToChange = New Structure();
		DataToChange.Insert("ItemList", ItemToChange);
		DataToChange.Insert("Period", Period);
		DataToChange.Insert("Country", Country);
		DataToChange.Insert("ListAddress", Undefined);
		
		If MultiCountryAccounting Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đặt hàng hóa đã chọn là không chịu thuế tiêu thụ đặc biệt đối với quốc gia ""%1"" từ %2?';
							|ru = 'Сделать выбранный товар неподакцизным для страны ""%1"" с %2?';
							|en = 'Make the selected product non-excisable for the ""%1"" country from %2?'; fa = 'Make the selected product non-excisable for the ""%1"" country from %2?';
							|it = 'Make the selected product non-excisable for the ""%1"" country from %2?';
							|pl = 'Make the selected product non-excisable for the ""%1"" country from %2?';
							|tr = '%2 olan ""%1"" ülke için seçili ürün tüketim vergisinden muaf hale getirilsin mi?'"),
						Country,
						Format(Period,"DLF=D"));
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đặt hàng hóa đã chọn là không chịu thuế tiêu thụ đặc biệt từ %1?';
							|ru = 'Сделать выбранный товар неподакцизным с %1?';
							|en = 'Make the selected item non-excisable from %1?'; fa = 'Make the selected item non-excisable from %1?';
							|it = 'Make the selected item non-excisable from %1?';
							|pl = 'Make the selected item non-excisable from %1?';
							|tr = '%1 olan seçili ürün tüketim vergisinden muaf hale getirilsin mi?'"),
						Format(Period,"DLF=D"));
		EndIf;
		
		ShowQueryBox(New CallbackDescription("ClearExcisableItemAttributeCompletion", ThisObject, DataToChange),
			QueryText,
			QuestionDialogMode.YesNo);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearExcisableAttributeForCurrentSelection(Command)
	
	If CheckFillingParameters(False) Then
		Return;
	EndIf;

	DataToChange = FillInDataForChangingItem(False, True);
	
	If DataToChange.ListAddress <> Undefined Then
		
		DataToChange.Insert("Period", Period);
		DataToChange.Insert("Country", Country);
		
		If MultiCountryAccounting Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đặt toàn bộ hàng hóa trong danh sách là không chịu thuế tiêu thụ đặc biệt đối với quốc gia ""%1"" từ %2?';
						|ru = 'Сделать весь товар в списке неподакцизным для страны ""%1"" с %2?';
						|en = 'Make all products in the list non-excisable for the ""%1"" country from %2?'; fa = 'Make all products in the list non-excisable for the ""%1"" country from %2?';
						|it = 'Make all products in the list non-excisable for the ""%1"" country from %2?';
						|pl = 'Make all products in the list non-excisable for the ""%1"" country from %2?';
						|tr = '%2 olan ""%1"" ülke için listedeki tüm ürünler tüketim vergisinden muaf hale getirilsin mi?'"),
					Country,
					Format(Period,"DLF=D"));
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đặt toàn bộ hàng hóa trong danh sách là không chịu thuế tiêu thụ đặc biệt từ %1?';
						|ru = 'Сделать весь товар в списке неподакцизным с %1?';
						|en = 'Make all the items in the list non-excisable from %1?'; fa = 'Make all the items in the list non-excisable from %1?';
						|it = 'Make all the items in the list non-excisable from %1?';
						|pl = 'Make all the items in the list non-excisable from %1?';
						|tr = '%1 olan listedeki tüm ürünler tüketim vergisinden muaf hale getirilsin mi?'"),
					Format(Period,"DLF=D"));
		EndIf;
		
		ShowQueryBox(New CallbackDescription("ClearExcisableItemAttributeCompletion", ThisObject, DataToChange),
			QueryText,
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfItemsCategory.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// 
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfItemsCategory.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ExcisableGoodsCategory");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указана>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListVolumeFactor.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListVolumeUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.VolumeUse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListWeightRatio.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListWeightUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.WeightUse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListConversionFactor_.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListCategoryUnit.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ItSFirmBet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListConversionFactor_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ItSFirmBet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ConversionFactor_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указана>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

&AtServer
Procedure UpdateListOfCategories()

	Items.SelectionCategory.ChoiceList.Clear();
	Items.SelectionCategory.ChoiceList.Add(0, NStr("vi = '<Bất kỳ>';
													|ru = '<Любая>';
													|en = '<Any>'; fa = '<هر>';
													|it = '<Any>';
													|pl = '<Any>';
													|tr = '<Herhangi>'"));
	Items.SelectionCategory.ChoiceList.Add(1, NStr("vi = '<Đã chỉ định>';
													|ru = '<Указана>';
													|en = '<Specified>'; fa = '<Specified>';
													|it = '<Specified>';
													|pl = '<Specified>';
													|tr = '<Belirtildi>'"));
	Items.SelectionCategory.ChoiceList.Add(2, NStr("vi = '<Chưa chỉ ra>';
													|ru = '<Не указана>';
													|en = '<Not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<Belirtilmedi>'"));

	Query = New Query;
	Query.Text =
	"SELECT TOP 10
	|	ExcisableGoodsCategories.Ref AS Category
	|FROM
	|	Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|WHERE
	|	ExcisableGoodsCategories.Country = &Country
	|	AND NOT ExcisableGoodsCategories.DeletionMark";
	
	Query.SetParameter("Country", Country);
	
	CategoryRows = Query.Execute().Select();
	
	While CategoryRows.Next() Do
		Items.SelectionCategory.ChoiceList.Add(CategoryRows.Category);
	EndDo;

	If CategoryRows.Count() > 10 Then
		Items.SelectionCategory.ChoiceList.Add(3, "...");
	EndIf;

	SelectionCategory = 0;
	SelectionCategoryUpTo = SelectionCategory;

EndProcedure

&AtServer
Procedure UpdateInformationByCategory()

	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(ItemsCategories.ExcisableGoodsCategory, VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) AS Category,
	|	COUNT(1) AS Count
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, Country = &Country) AS ItemsCategories
	|		ON CatalogProducts.Ref = ItemsCategories.Products
	|WHERE
	|	CatalogProducts.IsFolder = FALSE
	|
	|GROUP BY
	|	ISNULL(ItemsCategories.ExcisableGoodsCategory, VALUE(Catalog.ExcisableGoodsCategories.EmptyRef))
	|
	|ORDER BY
	|	Category";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("Country", Country);
	
	StringsList = New Array;
	StringsList.Add(NStr("vi = 'Toàn bộ mặt hàng với thể loại:';
						|ru = 'Всего номенклатуры с категориями:';
						|en = 'Total items with categories:'; fa = 'Total items with categories:';
						|it = 'Total items with categories:';
						|pl = 'Total items with categories:';
						|tr = 'Kategorileri içeren toplam öğe:'"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.Category) Then
			Category = NStr("vi = '<chưa chỉ ra>';
							|ru = '<не указана>';
							|en = '<not specified>'; fa = '<مشخص نشده>';
							|it = '<non indicata>';
							|pl = '<nie określono>';
							|tr = '<belirtilmedi>'");
		Else
			Category = Selection.Category;
		EndIf;
		StringsList.Add(StrTemplate(NStr("vi = '%1 - %2 mặt hàng.';
										|ru = '%1 - %2 шт.';
										|en = '%1 - %2 pcs.'; fa = '%1 - %2 pcs.';
										|it = '%1 - %2 pz.';
										|pl = '%1 - %2 szt.';
										|tr = '%1 - %2 tane.'"), Category, Selection.Count));
	EndDo;
		
	BidInformation = New FormattedString(StrConcat(StringsList, " "), , StyleColors.HelpText);
	
EndProcedure

&AtClient
Function CheckFillingParameters(CheckDestinationCategory = False)
	
	Cancel = False;
	
	If CheckDestinationCategory And Not ValueIsFilled(DestinationCategory) Then
		ErrorText = NStr("vi = 'Chưa chỉ định thể loại hàng hóa chịu thuế TTĐB';
						|ru = 'Не указана категория подакцизных товаров';
						|en = 'The excisable goods category is not specified'; fa = 'The excisable goods category is not specified';
						|it = 'The excisable goods category is not specified';
						|pl = 'The excisable goods category is not specified';
						|tr = 'Tüketim vergisine tabi ürünlerin kategorisi belirtilmedi'");
		CommonClient.MessageToUser(ErrorText, , "DestinationCategory", , Cancel);
	EndIf;
	
	If Not ValueIsFilled(Period) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra kỳ';
										|ru = 'Не указан период';
										|en = 'Period is not specified'; fa = 'Period is not specified';
										|it = 'Periodo non indicato';
										|pl = 'Nie podano okresu';
										|tr = 'Dönem belirtilmedi.'"), , "Period", , Cancel);
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtClient
Procedure SetExciseCategoryOfItemCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		SetExciseCategoryOfItemOnClient(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetExciseCategoryOfItemOnClient(AdditionalParameters)
	
	TimeConsumingOperation = SetExciseCategoryOfItemATServer(AdditionalParameters);
	
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("AfterEndOfBackgroundOfOperation", ThisObject,
			NStr("vi = 'Đã đặt thể loại chịu thuế TTĐB cho mặt hàng';
				|ru = 'Подакцизные категории номенклатуры установлены';
				|en = 'Excisable item categories are set'; fa = 'Excisable item categories are set';
				|it = 'Excisable item categories are set';
				|pl = 'Excisable item categories are set';
				|tr = 'Öğenin tüketim vergisine tabi kategorileri ayarlandı'"));
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputMessages = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure SettingEndFactor(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		AdditionalParameters.Insert("ConversionFactor_", Result.ConversionFactor_);
		
		TimeConsumingOperation = SetCoefficientATServer(AdditionalParameters);
	
		If TimeConsumingOperation <> Undefined Then
			CallbackOnCompletion = New CallbackDescription("AfterEndOfBackgroundOfOperation", ThisObject,
				NStr("vi = 'Đã đặt hệ số tính lại mặt hàng';
					|ru = 'Коэффициенты пересчета номенклатуры установлены';
					|en = 'Item conversion ratios are set'; fa = 'Item conversion ratios are set';
					|it = 'Item conversion ratios are set';
					|pl = 'Item conversion ratios are set';
					|tr = 'Öğenin dönüştürme oranı ayarlandı'"));
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputMessages = True;
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		EndIf;

	EndIf;
	
EndProcedure

&AtClient
Procedure ClearExcisableItemAttributeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		TimeConsumingOperation = ClearExciseAttributeOfItemAtServer(AdditionalParameters);
	
		If TimeConsumingOperation <> Undefined Then
			CallbackOnCompletion = New CallbackDescription("AfterEndOfBackgroundOfOperation", ThisObject,
			NStr("vi = 'Dấu hiệu chịu thuế TTĐB đã bị xóa khỏi mặt hàng';
				|ru = 'Подакцизный признак сброшен для номенклатуры';
				|en = 'Excisable flag is reset for the item'; fa = 'Excisable flag is reset for the item';
				|it = 'Excisable flag is reset for the item';
				|pl = 'Excisable flag is reset for the item';
				|tr = 'Tüketim vergisine tabi göstergesi öğe için sıfırlandı'"));
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputMessages = True;
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Function SetExciseCategoryOfItemATServer(AdditionalParameters)

	If AdditionalParameters.ListAddress <> Undefined Then
		AdditionalParameters.Insert("ItemList", GetFromTempStorage(AdditionalParameters.ListAddress));
	EndIf;
	
	MethodName = "InformationRegisters.ExcisableGoodsCategories.SetExciseCategoryOfItem";
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Đặt thể loại chịu thuế TTĐB cho mặt hàng';
													|ru = 'Установка подакцизных категорий номенклатуры';
													|en = 'Set excise item categories'; fa = 'Set excise item categories';
													|it = 'Set excise item categories';
													|pl = 'Set excise item categories';
													|tr = 'Tüketim vergisine tabi öğe kategorilerinin ayarlanması'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, AdditionalParameters);
	
EndFunction

&AtServer
Function ClearExciseAttributeOfItemAtServer(AdditionalParameters)
	
	If AdditionalParameters.ListAddress <> Undefined Then
		AdditionalParameters.Insert("ItemList", GetFromTempStorage(AdditionalParameters.ListAddress));
	EndIf;
	
	MethodName = "InformationRegisters.ExcisableGoodsCategories.ClearExcisableItemAttribute";
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Xóa thể loại chịu thuế TTĐB cho mặt hàng';
													|ru = 'Очистка подакцизных категорий номенклатуры';
													|en = 'Clear excisable item categories'; fa = 'Clear excisable item categories';
													|it = 'Clear excisable item categories';
													|pl = 'Clear excisable item categories';
													|tr = 'Tüketim vergisine tabi öğe kategorilerinin temizlenmesi'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, AdditionalParameters);
	
EndFunction

&AtServer
Function SetCoefficientATServer(AdditionalParameters)
	
	If AdditionalParameters.ListAddress <> Undefined Then
		AdditionalParameters.Insert("ItemList", GetFromTempStorage(AdditionalParameters.ListAddress));
	EndIf;
		
	MethodName = "InformationRegisters.ExcisableGoodsCategories.SetConversionRatioForList";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Đặt hệ số tính lại';
													|ru = 'Установка коэффициента пересчета';
													|en = 'Set conversion ratio'; fa = 'تعیین نسبت تبدیل';
													|it = 'Set conversion ratio';
													|pl = 'Set conversion ratio';
													|tr = 'Dönüştürme oranının ayarlanması'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, AdditionalParameters);

EndFunction

&AtClient
Procedure AfterEndOfBackgroundOfOperation(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each Message In Result.Messages Do
		Message.Message();
	EndDo;
	
	If Result.Status = "Error" Then
		CommonClient.MessageToUser(Result.BriefErrorDescription);
	ElsIf Result.Status = "Completed2" Then
		ShowUserNotification(AdditionalParameters);
		Items.ItemList.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Function FillInDataForChangingItem(CheckCategory = False, ExcisableOnly = False);
	
	DataToChange = New Structure;
	DataToChange.Insert("ListAddress", Undefined);
	DataToChange.Insert("ThereIsAlreadyEstablishedCategory", False);
	
	ItemData_3 = GetSelectionByItem();
	
	ItemToChange = New Array;
	While ItemData_3.Next() Do
		If CheckCategory And ValueIsFilled(ItemData_3.ExcisableGoodsCategory) Then
			DataToChange.ThereIsAlreadyEstablishedCategory = True;
		EndIf;
		If ExcisableOnly And Not ItemData_3.ExcisableGoods Then
			Continue;
		EndIf;
		ItemToChange.Add(ItemData_3.Ref);
	EndDo;
	
	If ItemToChange.Count() > 0 Then
		DataToChange.ListAddress = PutToTempStorage(ItemToChange, New UUID);
	EndIf;
	
	Return DataToChange;
	
EndFunction

&AtServer
Function GetParametersForRecalculatingCoefficient()
	
	CurrentRow = GetSelectionByItem();

	ItemToChange = New Array;
	ThereAreItemsWithoutCategory = False;
	AutocompletionOfConversionRatio = False;
	RequestCoefficient = False; 
	ThereAreDifferentUnits = False;
	UnitOfProductMeasurement_ = Undefined;
	ThereIsAdValoremRate = False;
	CategoryUnitOfMeasurement = Undefined;
	ThereAreDifferentUnitsOfCategory = False;

	While CurrentRow.Next() Do
		If Not ValueIsFilled(CurrentRow.ExcisableGoodsCategory) Then
			ThereAreItemsWithoutCategory = True;
			Break;
		EndIf;
		If Not CurrentRow.ItSFirmBet Then
			ThereIsAdValoremRate = True;
			Break;
		EndIf;
		
		If CategoryUnitOfMeasurement = Undefined Then
			CategoryUnitOfMeasurement = CurrentRow.CategoryUnit;
		ElsIf CategoryUnitOfMeasurement <> CurrentRow.CategoryUnit Then
			ThereAreDifferentUnitsOfCategory = True;
			Break;
		EndIf;
	
		If CurrentRow.AutocompletionOfConversionRatio = True Then
		    AutocompletionOfConversionRatio = True;
		Else
			RequestCoefficient = True;
		EndIf;
		If UnitOfProductMeasurement_ = Undefined Then
			UnitOfProductMeasurement_ = CurrentRow.UnitOfMeasure;
		EndIf;
		If Not ThereAreDifferentUnits
			And CurrentRow.UnitOfMeasure <> UnitOfProductMeasurement_ Then
			ThereAreDifferentUnits = True;
		EndIf;
		ItemToChange.Add(New Structure("Products, ExcisableGoodsCategory, AutoConversionRatio",
			CurrentRow.Ref, CurrentRow.ExcisableGoodsCategory, CurrentRow.AutoConversionRatio));
	EndDo;
	
	If ItemToChange.Count() > 0 Then
		AddressOfItemData = PutToTempStorage(ItemToChange, New UUID);
	Else
		AddressOfItemData = Undefined;
	EndIf;
	
	CoefficientFillingParameters = New Structure;
	CoefficientFillingParameters.Insert("Period", Period);
	CoefficientFillingParameters.Insert("Country", Country);	
	CoefficientFillingParameters.Insert("ListAddress", AddressOfItemData);
	CoefficientFillingParameters.Insert("AutocompletionOfConversionRatio", AutocompletionOfConversionRatio);
	CoefficientFillingParameters.Insert("RequestCoefficient", RequestCoefficient);
	CoefficientFillingParameters.Insert("AutocompletionOfConversionRatio", AutocompletionOfConversionRatio);
	CoefficientFillingParameters.Insert("RequestCoefficient", RequestCoefficient);
	CoefficientFillingParameters.Insert("ThereAreDifferentUnits", ThereAreDifferentUnits);
	CoefficientFillingParameters.Insert("ThereAreItemsWithoutCategory", ThereAreItemsWithoutCategory);
	CoefficientFillingParameters.Insert("ThereIsAdValoremRate", ThereIsAdValoremRate);
	CoefficientFillingParameters.Insert("CategoryUnitOfMeasurement", CategoryUnitOfMeasurement);
	CoefficientFillingParameters.Insert("ThereAreDifferentUnitsOfCategory", ThereAreDifferentUnitsOfCategory);
	
	Return CoefficientFillingParameters;
	
EndFunction

&AtServer
Function GetSelectionByItem()
	
	Schema = Items.ItemList.GetPerformingDataCompositionScheme();
	Settings = Items.ItemList.GetPerformingDataCompositionSettings();
		
	DataCompositionClientServer.AddFilter(Settings, "IsFolder", False);
		
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(Schema, Settings, , ,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Query = New Query;
	Query.Text = CompositionTemplate.DataSets.DynamicListDataSet.Query;	
	For Each ParameterValue In CompositionTemplate.ParameterValues Do
		Query.SetParameter(ParameterValue.Name,ParameterValue.Value);
	EndDo;
	
	Return Query.Execute().Select();

EndFunction

&AtServer
Procedure SetFilterByFlag()
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(
		ItemList,"ExcisableGoods");

	If ExcisableGoods <> 0 Then
	CommonClientServer.SetDynamicListFilterItem(
		ItemList,
		"ExcisableGoods",
		?(ExcisableGoods = 1, True, False),
		DataCompositionComparisonType.Equal,
		,
		True);
	EndIf;
	
	If ((ExcisableGoods = 1 Or ExcisableGoods = 0) And SelectionCategory = 0)
		Or ExcisableGoods = 2 Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(
		ItemList,"ExcisableGoodsCategory");
	ElsIf (ExcisableGoods = 1 Or ExcisableGoods = 0) And SelectionCategory = 1 Then
		CommonClientServer.SetDynamicListFilterItem(
			ItemList,
			"ExcisableGoodsCategory",
			,
			DataCompositionComparisonType.Filled);
	ElsIf (ExcisableGoods = 1 Or ExcisableGoods = 0) And SelectionCategory = 2 Then
		CommonClientServer.SetDynamicListFilterItem(
			ItemList,
			"ExcisableGoodsCategory",
			,
			DataCompositionComparisonType.NotFilled);
	ElsIf (ExcisableGoods = 1 Or ExcisableGoods = 0) And ValueIsFilled(SelectionCategory) Then
		CommonClientServer.SetDynamicListFilterItem(
			ItemList,
			"ExcisableGoodsCategory",
			SelectionCategory,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	If (ExcisableGoods = 1 Or ExcisableGoods = 0) And TypeOf(ConversionRatioSelection) = Type("String") Then
		If ConversionRatioSelection = "<All>" Then
			CommonClientServer.DeleteDynamicListFilterGroupItems(
				ItemList,"ConversionFactor_");
			CommonClientServer.DeleteDynamicListFilterGroupItems(
				ItemList,"ItSFirmBet");
		ElsIf ConversionRatioSelection = "<Specified>" Then
			CommonClientServer.SetDynamicListFilterItem(
				ItemList,
				"ConversionFactor_",
				,
				DataCompositionComparisonType.Filled);
		ElsIf ConversionRatioSelection = "<Not specified>" Then
			CommonClientServer.SetDynamicListFilterItem(
				ItemList,
				"ConversionFactor_",
				,
				DataCompositionComparisonType.NotFilled);
			CommonClientServer.SetDynamicListFilterItem(
				ItemList,
				"ItSFirmBet",
				True,
				DataCompositionComparisonType.Equal);
		EndIf;
	ElsIf (ExcisableGoods = 1 Or ExcisableGoods = 0) And TypeOf(ConversionRatioSelection) = Type("Number") Then
			CommonClientServer.SetDynamicListFilterItem(
				ItemList,
				"ConversionFactor_",
				ConversionRatioSelection,
				DataCompositionComparisonType.Equal);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(
			ItemList,"ConversionFactor_");
		CommonClientServer.DeleteDynamicListFilterGroupItems(
			ItemList,"ItSFirmBet");
	EndIf;
	
	ItemsAvailability = ExcisableGoods <> 2;
	Items.SelectionCategory.Enabled = ItemsAvailability;
	Items.ConversionRatioSelection.Enabled = ItemsAvailability;
	
EndProcedure

&AtServer
Procedure SetTypeOfExciseUnit()
	
	HideItemWeightAndVolume = True;
	
	If ValueIsFilled(DestinationCategory) Then
		CategoryDetails = Common.ObjectAttributesValues(DestinationCategory, "RateType, UnitOfMeasure");
		If CategoryDetails.RateType = Enums.TypesOfExcisableCategoryRates.FixedRate
			And ValueIsFilled(CategoryDetails.UnitOfMeasure) Then
			MeasuredValueType = Common.ObjectAttributeValue(CategoryDetails.UnitOfMeasure, "MeasuredValueType");
			If MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3 Then
				HideItemWeightAndVolume = False;
				Items.ItemListVolumeFactor.Visible = True;
				Items.ItemListVolumeUnitOfMeasure.Visible = True;
			ElsIf MeasuredValueType = Enums.TypesOfMeasuredValues.Weight Then
				HideItemWeightAndVolume = False;
				Items.ItemListWeightRatio.Visible = True;
				Items.ItemListWeightUnitOfMeasure.Visible = True;
			EndIf;
		EndIf;
	EndIf;
	
	If HideItemWeightAndVolume Then
		Items.ItemListVolumeFactor.Visible = False;
		Items.ItemListVolumeUnitOfMeasure.Visible = False;
		Items.ItemListWeightRatio.Visible = False;
		Items.ItemListWeightUnitOfMeasure.Visible = False;
	EndIf;
	
	SetFilterByFlag();

EndProcedure

&AtClient
Procedure ToRequestCoefficient(Var_Parameters) Export
	
	ShowInputNumber(New CallbackDescription("SelectEndFactor", ThisObject), 1, 
			NStr("vi = 'Hãy nhập hệ số tính lại';
				|ru = 'Введите коэффициент пересчета';
				|en = 'Enter conversion ratio'; fa = 'Enter conversion ratio';
				|it = 'Enter conversion ratio';
				|pl = 'Enter conversion ratio';
				|tr = 'Dönüştürme oranı girin'"), 10, 6);
	
EndProcedure

&AtClient
Procedure SelectEndFactor(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		
		If Result < 0 Then
			ErrorText = NStr("vi = 'Hệ số không được phép âm.';
							|ru = 'Коэффициент не должен быть отрицательным числом.';
							|en = 'The ratio cannot be a negative number.'; fa = 'The ratio cannot be a negative number.';
							|it = 'The ratio cannot be a negative number.';
							|pl = 'The ratio cannot be a negative number.';
							|tr = 'Oran negatif bir sayı olmamalıdır.'");
			WarningTitle = NStr("vi = 'Lỗi nhập hệ số';
								|ru = 'Ошибка ввода коэффициента';
								|en = 'Ratio input error'; fa = 'Ratio input error';
								|it = 'Ratio input error';
								|pl = 'Ratio input error';
								|tr = 'Oran girilirken hata oluştu'");
			ShowMessageBox(New CallbackDescription("ToRequestCoefficient", ThisObject),
				ErrorText,
				,
				WarningTitle);
		Else
			ChoiceItem = Items.ConversionRatioSelection.ChoiceList.FindByValue(Result);
			If ChoiceItem = Undefined Then
				CoefficientRow = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Hệ số ""%1""';
						|ru = 'Коэффициент ""%1""';
						|en = 'The ""%1"" ratio'; fa = 'The ""%1"" ratio';
						|it = 'The ""%1"" ratio';
						|pl = 'The ""%1"" ratio';
						|tr = '""%1"" oranı'"), Format(Result, "ND=10; NFD=6"));
				Items.ConversionRatioSelection.ChoiceList.Add(Result, CoefficientRow);
				If Items.ConversionRatioSelection.ChoiceList.Count() > 10 Then
					For Each ConversionRatioLine In Items.ConversionRatioSelection.ChoiceList Do
						If TypeOf(ConversionRatioLine.Value) = Type("Number") Then
							Items.ConversionRatioSelection.ChoiceList.Delete(ConversionRatioLine);
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			ConversionRatioSelection = Result;
			ConversionRatioSelectionTo = ConversionRatioSelection;
			
			SetFilterByFlag();
		EndIf;
	Else
		ConversionRatioSelection = ConversionRatioSelectionTo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionOfExciseCategoryEnd(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		SelectionCategory = Result;
		SetFilterByFlag();
		SelectionCategoryUpTo = SelectionCategory;
	Else
		SelectionCategory = SelectionCategoryUpTo;
	EndIf;
	
EndProcedure

&AtClient
Function DisplayWarningWhenSettingCoefficient(ThereAreItemsWithoutCategory, ThereIsAdValoremRate, AutoFillingAndRequestingCoefficient, ThereAreDifferentUnitsOfCategory, ThereIsNoItemSelected)
	
	Cancel = True;
	
	If ThereAreItemsWithoutCategory Then
		ShowMessageBox(, NStr("vi = 'Không thể chỉ định hệ số tính lại, nếu chưa đặt thể loại cho mặt hàng.';
								|ru = 'Нельзя указать коэффициент пересчета, если для номенклатуры не задана категория.';
								|en = 'Cannot specify a conversion ratio if the category is not specified for the item.'; fa = 'Cannot specify a conversion ratio if the category is not specified for the item.';
								|it = 'Cannot specify a conversion ratio if the category is not specified for the item.';
								|pl = 'Cannot specify a conversion ratio if the category is not specified for the item.';
								|tr = 'Öğenin kategorisi belirtilmemiş ise dönüştürme oranı belirtemezsiniz.'"));
	ElsIf ThereIsAdValoremRate Then
		ShowMessageBox(, NStr("vi = 'Đã chọn hàng hóa chịu thuế TTĐB với các thể loại có chỉ định thuế suất theo giá trị.
			|Đối với các thể loại này, không hỗ trợ tính tự động số tiền thuế TTĐB. Không cần nhập hệ số tính lại.';
			|ru = 'Выбраны подакцизные товары с категориями, в которых указаны адвалорные ставки.
			|Для таких категорий не поддерживается автоматический расчет сумм акциза. Вводить коэффициент пересчета не надо.';
			|en = 'Excisable goods with ad valorem rates are selected.
			|Automatic calculation of excise amounts is not supported for these categories. There is no need to enter a conversion ratio.'; fa = 'Excisable goods with ad valorem rates are selected.
			|Automatic calculation of excise amounts is not supported for these categories. There is no need to enter a conversion ratio.';
			|it = 'Excisable goods with ad valorem rates are selected.
			|Automatic calculation of excise amounts is not supported for these categories. There is no need to enter a conversion ratio.';
			|pl = 'Excisable goods with ad valorem rates are selected.
			|Automatic calculation of excise amounts is not supported for these categories. There is no need to enter a conversion ratio.';
			|tr = 'Ad valorem oranlarının belirtildiği kategorilere sahip tüketim vergisine tabi ürünler seçildi.
			|Bu kategoriler için tüketim vergisi tutarlarının otomatik hesaplanması desteklenmemektedir. Dönüştürme oranı girilmesine gerek yoktur.'"));
	ElsIf AutoFillingAndRequestingCoefficient Then
		ShowMessageBox(, NStr("vi = 'Đã chọn các mặt hàng chịu thuế tiêu thụ đặc biệt, trong đó có những mặt hàng có thể tự động tính hệ số và những mặt hàng cần nhập hệ số thủ công.';
								|ru = 'Выбраны подакцизные товары, для которых возможен авторасчет коэффициента и для которых необходимо задавать коэффициент вручную.';
								|en = 'Excisable goods are selected for which automatic ratio calculation is available and for which it is necessary to set the ratio manually.'; fa = 'Excisable goods are selected for which automatic ratio calculation is available and for which it is necessary to set the ratio manually.';
								|it = 'Excisable goods are selected for which automatic ratio calculation is available and for which it is necessary to set the ratio manually.';
								|pl = 'Excisable goods are selected for which automatic ratio calculation is available and for which it is necessary to set the ratio manually.';
								|tr = 'Oranın otomatik hesaplanmasının mümkün olduğu ve oran değerinin manuel olarak belirlenmesinin gerektiği tüketim vergisine tabi ürünler seçildi.'"));
	ElsIf ThereAreDifferentUnitsOfCategory Then
		ShowMessageBox(, NStr("vi = 'Đã chọn các mặt hàng chịu thuế TTĐB có đơn vị tính của thể loại hàng chịu thuế TTĐB khác nhau.
			|Có thể đặt hệ số tính lại chỉ cho các mặt hàng có cùng đơn vị tính thuộc thể loại chịu thuế TTĐB.';
			|ru = 'Выбраны подакцизные товары с разными единицами измерения подакцизных категорий.
			|Установить коэффициент пересчета можно для товаров с одинаковыми единицами измерения подакцизных категорий.';
			|en = 'Excisable goods with different units of measure of excisable categories are selected.
			|You can set the conversion ratio for goods with the same units of measure of excisable categories.'; fa = 'Excisable goods with different units of measure of excisable categories are selected.
			|You can set the conversion ratio for goods with the same units of measure of excisable categories.';
			|it = 'Excisable goods with different units of measure of excisable categories are selected.
			|You can set the conversion ratio for goods with the same units of measure of excisable categories.';
			|pl = 'Excisable goods with different units of measure of excisable categories are selected.
			|You can set the conversion ratio for goods with the same units of measure of excisable categories.';
			|tr = 'Tüketim vergisine tabi kategorilerin farklı ölçü birimlerine sahip tüketim vergisine tabi ürünler seçildi.
			|Tüketim vergisine tabi kategorilerin aynı ölçü birimlerine sahip ürünler için dönüştürme oranı belirlemek mümkündür.'"));
	ElsIf ThereIsNoItemSelected Then
		ShowMessageBox(, NStr("vi = 'Để tiếp tục, cần chọn các dòng.';
								|ru = 'Для продолжения необходимо выделить строки.';
								|en = 'To continue, select lines.'; fa = 'To continue, select lines.';
								|it = 'To continue, select lines.';
								|pl = 'To continue, select lines.';
								|tr = 'Devam etmek için satırları seçmeniz gerekmektedir.'"));
	Else
		Cancel = False;
	EndIf;
	
	Return Cancel;

EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_Period" Then
		PeriodOnChange(Items.Period);
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
