
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ReadFO();
	
	SetFOSettings();
	
	OverridePropertiesOfDynamicLists();
	
	SetConditionalAppearance();
	
	InitializeDynamicLists();
	
	Items.List.ChangeRowSet = GetFunctionalOption("UseSeveralPriceTypes");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Items.Find("ItemOrderSetup") <> Undefined Then
		Items["ItemOrderSetup"].Visible = AccessRight("Update", Metadata.Catalogs.TypesOfPrices);
	EndIf;
	
	Items.ConfigureRangeOfAllowablePrices.Visible = 
		  AccessRight("Read", Metadata.Constants.KindOfMaximumAllowablePurchasePrice)
		And AccessRight("Read", Metadata.Constants.KindOfMaximumAllowableSellingPrices)
		And AccessRight("Read", Metadata.Constants.KindOfMinimumAllowableSellingPrices);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	FillingCommandMenuInBookmarks();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OptionForDisplayingPriceTypesWhenChanging(Item)
	
	MatchingBookmarks = GetBookmarkContent();
	If MatchingBookmarks = Undefined Then
		Return;
	EndIf; 
	
	OptionForDisplayingPriceTypes = ThisObject[MatchingBookmarks.NameOptionForDisplayingPriceTypes]; 
	
	ChangingDynamicListFilter(MatchingBookmarks);

EndProcedure

&AtServer
Procedure InitializeDynamicLists()
	
	DynamicLists = New Array;
	
	If ToUseTermsOfSales Then
		DynamicLists.Add(UseInCustomerAgreements_);
	EndIf;
	
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;	
	
	If UseStoreFormats Then
		DynamicLists.Add(UseInStoreFormats);
	EndIf;
	
	If UsePartners Then
		DynamicLists.Add(UseInPartners);
	EndIf;
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"PricesKind",
			Undefined,
			True);
			
	EndDo;
	
	If UseSeveralWarehouses Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInWarehouses,
			"Status",
			Enums.StatusesOfPriceTypeValidity.Valid,
			DataCompositionComparisonType.Equal,
			,
			OptionForDisplayingPriceTypes <> "All");
	EndIf;
	
	If UseStoreFormats Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInStoreFormats,
			"Status",
			Enums.StatusesOfPriceTypeValidity.Valid,
			DataCompositionComparisonType.Equal,
			,
			OptionForDisplayingPriceTypes <> "All");
	EndIf;
		
	If UsePartners Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInPartners,
			"Status",
			Enums.StatusesOfPriceTypeValidity.Valid,
			DataCompositionComparisonType.Equal,
			,
			OptionForDisplayingPriceTypes <> "All");
	EndIf;
		
	If ToUseTermsOfSales Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInCustomerAgreements_,
			"Status",
			Enums.StatusesOfPriceTypeValidity.Valid,
			DataCompositionComparisonType.Equal,
			,
			OptionForDisplayingPriceTypes <> "All");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status", StatusFilter, DataCompositionComparisonType.Equal,, ValueIsFilled(StatusFilter));

	CommonClientServer.SetDynamicListFilterItem(
		List, "Purpose", PurposeSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(PurposeSelection));

	ChangeUsageSelection();

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ListParameters = Settings.DataParameters.Items;
	
	Query = New Query;
	Query.Text = DynamicListQueryText1(ListParameters);
	
	Query.SetParameter("ReferencesArrray", Rows.GetKeys());
	
	DataListLine = Undefined;
	
	DetailsForFillIn = New Array();
	FoundParameter = ListParameters.Find("UseSeveralWarehouses");
	If ?(FoundParameter = Undefined, False, FoundParameter.Value) Then
		DetailsForFillIn.Add("NumberOfWarehousesTotal");
		NumberOfWarehouses = "NumberOfWarehouses";
	Else
		NumberOfWarehouses = "";
	EndIf;
	
	FoundParameter = ListParameters.Find("UseStoreFormats");
	If ?(FoundParameter = Undefined, False, FoundParameter.Value) Then
		DetailsForFillIn.Add("NumberOfStoreFormatsTotal");
		NumberOfStoreFormats = "NumberOfStoreFormats";
	Else
		NumberOfStoreFormats = "";
	EndIf;

	FoundParameter = ListParameters.Find("UsePartners");
	If ?(FoundParameter = Undefined, False, FoundParameter.Value) Then
		DetailsForFillIn.Add("NumberOfPartnersTotal");
		NumberOfPartners = "NumberOfPartners";
	Else
		NumberOfPartners = "";
	EndIf;

	FoundParameter = ListParameters.Find("ToUseTermsOfSales");
	If ?(FoundParameter = Undefined, False, FoundParameter.Value) Then
		DetailsForFillIn.Add("NumberOfAgreementsTotal");
		NumberOfAgreements = "NumberOfAgreements";
	Else
		NumberOfAgreements = "";
	EndIf;
	
	OutputOfAttributesToListHasBeenChecked = False;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		DataListLine = Rows[Selection.PriceKind].Data;
		If Not OutputOfAttributesToListHasBeenChecked Then
			If Not IsBlankString(NumberOfWarehouses)
				And DataListLine.Property(NumberOfWarehouses) Then
				DetailsForFillIn.Add(NumberOfWarehouses);
			EndIf;
			If Not IsBlankString(NumberOfStoreFormats)
				And DataListLine.Property(NumberOfStoreFormats) Then
				DetailsForFillIn.Add(NumberOfStoreFormats);
			EndIf;
			If Not IsBlankString(NumberOfPartners)
				And DataListLine.Property(NumberOfPartners) Then
				DetailsForFillIn.Add(NumberOfPartners);
			EndIf;
			If Not IsBlankString(NumberOfAgreements)
				And DataListLine.Property(NumberOfAgreements) Then
				DetailsForFillIn.Add(NumberOfAgreements);
			EndIf;
			LineDetailsToFillIn = StrConcat(DetailsForFillIn, ", ");
			OutputOfAttributesToListHasBeenChecked = True;
		EndIf;
		FillPropertyValues(DataListLine, Selection, LineDetailsToFillIn);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureRangeOfAllowablePricesExecute()
	
	OpenForm("Catalog.TypesOfPrices.Form.SettingsFormOfAllowablePriceRange",,,,);

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	If Not ThereIsUpdateWhenListIsActivatedWhenLineIsActivated Then
		ThereIsUpdateWhenListIsActivatedWhenLineIsActivated = True;
		AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateCell(Item)

	If BookmarksAreBeingSwitched Or Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	SwitchingUseOfPriceTypes(Item.CurrentItem.Name);

EndProcedure

&AtClient
Procedure SetUpAScheduleForAutoUpdatingPrices(Command)
	
	OpenForm("Catalog.TypesOfPrices.Form.AutoUpdateScheduleSettingsForm",,,,);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Status", StatusFilter, DataCompositionComparisonType.Equal,, ValueIsFilled(StatusFilter));

EndProcedure

&AtClient
Procedure TypeOfPriceTypeSelectionWhenChanging(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Purpose", PurposeSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(PurposeSelection));
		
EndProcedure

&AtClient
Procedure UseFilterOnChange(Item)

	ChangeUsageSelection();
	
EndProcedure

&AtServer
Procedure ChangeUsageSelection()
	
	For Each Item In Items.UseFilter.ChoiceList Do
			
		FlagValues = (UseFilter = Item.Value);
		
		CommonClientServer.SetDynamicListFilterItem(
			List, Item.Value, FlagValues, DataCompositionComparisonType.Equal,, FlagValues);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	DataOnTypeOfPrices = CurPriceData();
	If Not DataOnTypeOfPrices.PricesKind.IsEmpty() 
		And DataOnTypeOfPrices.PricesKind <> ActivatedKindOfPrices Then
		
		AvailabilityOfStoreFormats = (ValueIsFilled(DataOnTypeOfPrices.PricesKind) And DataOnTypeOfPrices.UseForRetailSalesToCustomers);
		Items.StoreFormatsGroup.Enabled		= AvailabilityOfStoreFormats;
		Items.TeamInStoreFormats1.Enabled = AvailabilityOfStoreFormats;
		Items.LabelQuantityInStoreFormats.Enabled  = AvailabilityOfStoreFormats;
		Items.TeamInStoreFormats3.Enabled = AvailabilityOfStoreFormats;
		Items.TeamInStoreFormats4.Enabled = AvailabilityOfStoreFormats;
		
		PriceTypeSelected = Not DataOnTypeOfPrices.PricesKind.IsEmpty();
		
		Items.CurrentPriceUsageGroup.Enabled	= PriceTypeSelected;
		If DataOnTypeOfPrices.Purpose = PredefinedValue("Enum.PriceTypesAssignment.Shared") Then
			Items.ControlPanelGroup.Enabled  = PriceTypeSelected;
			
			Items.UseInWarehousesHeader.Enabled	= True;
			Items.UsageInHeaderFormats.Enabled	= True;
			Items.UseInPartnersCap.Enabled	= True;
			Items.UsageInCapAgreements.Enabled	= True;
		Else		
			Items.UseInWarehousesHeader.Enabled	= False;
			Items.UsageInHeaderFormats.Enabled	= False;
			Items.UseInPartnersCap.Enabled	= False;
			Items.UsageInCapAgreements.Enabled	= False;
		EndIf;
		
		ListWhenActivatingLineOnServer(DataOnTypeOfPrices);
		
	EndIf;
	
	ActivatedKindOfPrices = DataOnTypeOfPrices.PricesKind;
	ThereIsUpdateWhenListIsActivatedWhenLineIsActivated = False;
	
EndProcedure

&AtClient
Function CurPriceData()

	DataOnTypeOfPrices = InitializingDataStructureByPriceType(); 
	
	CurrentData = Items.List.CurrentData;
	If Not (CurrentData = Undefined 
		Or CurrentData.IsFolder 
		Or Items.List.SelectedRows.Count() <> 1) Then
			
		DataOnTypeOfPrices.PricesKind = CurrentData.Ref; 
		FillPropertyValues(DataOnTypeOfPrices, CurrentData);
		
	EndIf;
	
	Return DataOnTypeOfPrices;
	
EndFunction

&AtClient
Procedure TheInscriptionOnTheWarehousePress(Item)
	SwitchingUseOfPriceTypes(Item.Name);
EndProcedure

&AtClient
Procedure TheInscriptionInTheShopPress(Item)
	SwitchingUseOfPriceTypes(Item.Name);
EndProcedure

&AtClient
Procedure TheInscriptionInThePartnersPress(Item)
	SwitchingUseOfPriceTypes(Item.Name);
EndProcedure

&AtClient
Procedure TheInscriptionInTheAgreementsPress(Item)
	SwitchingUseOfPriceTypes(Item.Name);
EndProcedure

&AtClient
Procedure SwitchingUseOfPriceTypes(TagName)
	
	BookmarksAreBeingSwitched = True;
	MatchingBookmarks = GetBookmarkContent("Scope" , TagName);
	If MatchingBookmarks = Undefined Then
		BookmarksAreBeingSwitched = False;
		Return;
	EndIf; 
	Items.GroupPages.CurrentPage = Items[MatchingBookmarks.BookmarkName];
	Items.ControlPanelGroup.CurrentPage = Items[MatchingBookmarks.NameControlPanel];
	
	Items.List.CurrentItem = Items[MatchingBookmarks.Scope];
	
	ThisObject[MatchingBookmarks.NameOptionForDisplayingPriceTypes] = OptionForDisplayingPriceTypes;
	
	ChangingDynamicListFilter(MatchingBookmarks);
	BookmarksAreBeingSwitched = False;
	
EndProcedure

&AtServer
Procedure ListWhenActivatingLineOnServer(DataOnTypeOfPrices)
	
	DynamicLists = New Array;
	If ToUseTermsOfSales Then
		DynamicLists.Add(UseInCustomerAgreements_);
	EndIf;
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;
	If UseStoreFormats Then
		DynamicLists.Add(UseInStoreFormats);
	EndIf;
	If UsePartners Then
		DynamicLists.Add(UseInPartners);
	EndIf;
	
	PriceTypeSelected = Not DataOnTypeOfPrices.PricesKind.IsEmpty();
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"PricesKind",
			?(PriceTypeSelected, DataOnTypeOfPrices.PricesKind, Undefined),
			True);
		
	EndDo;
	
	GenerateInformationAboutNumberOfPriceTypesUsed(DataOnTypeOfPrices);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ListUseInCustomerAgreementsConditionalAppearance = UseInCustomerAgreements_.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInCustomerAgreementsConditionalAppearance.Items.Clear();
	
	ListUseInWarehousesConditionalAppearance = UseInWarehouses.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInWarehousesConditionalAppearance.Items.Clear();

	ListUsageInStoreFormatsConditionalAppearance = UseInStoreFormats.SettingsComposer.Settings.ConditionalAppearance;
	ListUsageInStoreFormatsConditionalAppearance.Items.Clear();

	ListUseInPartnersConditionalAppearance = UseInPartners.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInPartnersConditionalAppearance.Items.Clear();

	If UseSeveralWarehouses Then
	
		Item = ListUseInWarehousesConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.StatusesOfPriceTypeValidity.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If UseStoreFormats Then
	
		Item = ListUsageInStoreFormatsConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.StatusesOfPriceTypeValidity.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If UsePartners Then
	
		Item = ListUseInPartnersConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.StatusesOfPriceTypeValidity.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If ToUseTermsOfSales Then
	
		Item = ListUseInCustomerAgreementsConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.StatusesOfPriceTypeValidity.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ConvolutionScanCommand(Command)
	Items.CurrentPriceUsageGroup.Visible 	= Not Items.CurrentPriceUsageGroup.Visible;
	Items.ControlPanelGroup.Visible 			= Items.CurrentPriceUsageGroup.Visible;
	
	If Items.CurrentPriceUsageGroup.Visible Then
		Items.ConvolutionScanCommand.Title	= NStr("vi = 'Cuộn lại>>';
													|ru = 'Свернуть>>';
													|en = 'Collapse>>'; fa = 'جمع کردن>>';
													|it = 'Ridurre>>';
													|pl = 'Collapse>>';
													|tr = 'Daralt>>'");
	Else		
		Items.ConvolutionScanCommand.Title	= NStr("vi = '<<Mở cuộn';
													|ru = '<<Развернуть';
													|en = '<<Expand'; fa = '<<Expand';
													|it = '<<Espandere';
													|pl = '<<Expand';
													|tr = '<<Genişlet'");
	EndIf; 
EndProcedure

&AtClient
Procedure SetTheActiveRetailStatus(Command)
	GroupStatusChange(True,"Retail_2");
EndProcedure

&AtClient
Procedure SetTheStatusNotValidRetail(Command)
	GroupStatusChange(False,"Retail_2");
EndProcedure

&AtClient
Procedure SetTheStatusActiveAccount(Command)
	GroupStatusChange(True,"Accounting_0");
EndProcedure

&AtClient
Procedure SetTheStatusNotValidAccount(Command)
	GroupStatusChange(False,"Accounting_0");
EndProcedure

#EndRegion

#Region Private

#Region SettingRemovingStatuses

&AtClient
Procedure GroupStatusChange(Val IsInstallation = False,Val PriceKind)
	
	ClearMessages();
	
	ActivePage = Items.GroupPages.CurrentPage;
	
	If ActivePage = Undefined Then
		UserMessage = NStr("vi = 'Lỗi: không xác định thể loại đối tượng để thay đổi dạng giá';
							|ru = 'Ошибка: не определена категория объектов для изменения вида цен';
							|en = 'Error: object category is not defined for changing price type'; fa = 'Error: object category is not defined for changing price type';
							|it = 'Errore: non è stata definita la categoria di oggetti per la modifica del tipo di prezzo';
							|pl = 'Błąd: nie określono kategorii obiektów dla zmiany cen';
							|tr = 'Hata: Fiyat türünün değiştirilmesi için nesne kategorisi tanımlanmadı'");
		CommonClientServer.MessageToUser(UserMessage);
		Return;
	EndIf; 
	GroupStatusChangeServer(ActivePage.Name,IsInstallation,PriceKind);
	
	MatchingBookmarks = GetBookmarkContent();
	If MatchingBookmarks <> Undefined Then
		PriceUsageElement = Items[MatchingBookmarks.ListName];
		PriceUsageElement.Refresh();
	EndIf; 
		
EndProcedure

&AtServer
Procedure GroupStatusChangeServer(Val CollectionName, Val IsInstallation = False,Val PriceKind)
	
	Filter = New Structure("BookmarkName", CollectionName);
	FoundItems1 = MappingBookmarksToLists.FindRows(Filter);
	If FoundItems1.Count() > 0 Then
		MatchingBookmarks = New Structure("BookmarkName, ListName, Scope");
		FillPropertyValues(MatchingBookmarks, FoundItems1[0]);
	Else
		Return;
	EndIf;
	
	If MatchingBookmarks = Undefined Then
		UserMessage = NStr("vi = 'Đối với thể loại ""%1"" chưa xác định nguồn dữ liệu';
							|ru = 'Для категирии ""%1"" не определен источник данных';
							|en = 'No data source defined for category ""%1""'; fa = 'No data source defined for category ""%1""';
							|it = 'Per la categoria ""%1"" non è stata definita la sorgente dei dati';
							|pl = 'Dla kategorii ""%1"" nie określono źródła danych';
							|tr = '""%1"" kategorisi için veri kaynağı tanımlanmadı'");
		UserMessage = StringFunctionsClientServer.SubstituteParametersToString(UserMessage,CollectionName);
		Common.MessageToUser(UserMessage);
	EndIf; 
	
	ListOfPrices = Items.List;
	PriceUsageElement = Items[MatchingBookmarks.ListName];

	If ListOfPrices.SelectedRows.Count() = 1 Then
		CurViewPrices = ListOfPrices.SelectedRows[0];
		If Common.ObjectAttributeValue(CurViewPrices,"IsFolder") Then
			UserMessage = NStr("vi = 'Chỉ được phép thao tác đối với các phần tử dạng giá';
								|ru = 'Действие допустимо только для элементов видов цен';
								|en = 'The action is only valid for price types elements'; fa = 'The action is only valid for price types elements';
								|it = 'L''azione è possibile solamente per gli elementi dei tipi di prezzo';
								|pl = 'Działanie jest dopuszczalne tylko dla elementów rodzajów cen';
								|tr = 'Bu işlem sadece fiyat türü öğeleri için geçerlidir'");
			Common.MessageToUser(UserMessage);
			Return;
		EndIf; 
	ElsIf ListOfPrices.SelectedRows.Count() = 0 Then
		UserMessage = NStr("vi = 'Chưa chỉ ra dạng giá';
							|ru = 'Не указан вид цен';
							|en = 'Price type is not specified'; fa = 'Price type is not specified';
							|it = 'Tipo di prezzo non indicato';
							|pl = 'Nie podano rodzaju cen';
							|tr = 'Fiyat türü belirtilmedi'");
		Common.MessageToUser(UserMessage);
		Return;
	ElsIf ListOfPrices.SelectedRows.Count() > 1 Then
		UserMessage = NStr("vi = 'Không thể chỉ ra hơn một phần tử dạng giá';
							|ru = 'Указание более одного элемента вида цен недопустимо';
							|en = 'Specifying more than one price type element is not allowed'; fa = 'Specifying more than one price type element is not allowed';
							|it = 'Non è possibile indicare più di un elemento del tipo di prezzo';
							|pl = 'Wyznaczenie ponad jednego elementu rodzaju ten jest niedopuszczalne';
							|tr = 'Birden fazla fiyat türü öğesinin belirtilmesi izin verilmemektedir'");
		Common.MessageToUser(UserMessage);
		Return;
	ElsIf PriceUsageElement.SelectedRows.Count() = 0 Then
		UserMessage = NStr("vi = 'Chưa chỉ ra dữ liệu để đặt dạng giá';
							|ru = 'Не указаны данные для установки видов цен';
							|en = 'Data for setting price types is not specified'; fa = 'Data for setting price types is not specified';
							|it = 'Non sono indicati i dati per l''impostazione dei tipi di prezzo';
							|pl = 'Nie podano danych dla ustawienia rodzajów cen';
							|tr = 'Fiyat türlerinin yapılandırılması için veri belirtilmedi'");
		Common.MessageToUser(UserMessage);
		Return;
	EndIf;
	 
	If PriceUsageElement.SelectedRows.Count() = 0 Then
		UserMessage = NStr("vi = 'Chưa chỉ ra dữ liệu để đặt/bỏ dạng giá';
							|ru = 'Не указаны данные для установки/снятия видов цен';
							|en = 'Data for setting/removing price types is not specified'; fa = 'Data for setting/removing price types is not specified';
							|it = 'Non sono indicati i dati per l''impostazione/rimozione dei tipi di prezzo';
							|pl = 'Nie podano danych ustawienia/usunięcia rodzajów cen';
							|tr = 'Fiyat türlerinin yapılandırılması /kaldırılması için herhangi bir veri belirtilmedi'");
		Common.MessageToUser(UserMessage);
		Return;
	EndIf; 
	
	Catalogs.TypesOfPrices.SetTypeOfPriceInObjects(
		ListOfPrices.SelectedRows[0],IsInstallation,PriceUsageElement.SelectedRows,PriceKind);
	
EndProcedure

&AtServer
Procedure FillingCommandMenuInBookmarks()
	
	ListOfBookmarksToEmbed();
	
	For Each Item In MappingBookmarksToLists Do
		
		FormGroup = Items.Find(Item.GroupNameChangeStatus);
		If FormGroup = Undefined Then
			Continue;
		EndIf;
		
		If FormGroup.ChildItems.Count() = 0 Then
			InsertBefore_ = Undefined;
		Else
			InsertBefore_ = FormGroup.ChildItems[0];
		EndIf; 
		
		FormGroup.ShowTitle = False;
		
		MatchingBookmarks = GetBookmarkContentServer("Scope", Item.Scope);
		// RadioButton
		FormAttributeName = MatchingBookmarks.NameOptionForDisplayingPriceTypes;
		
		TagName = StringFunctionsClientServer.SubstituteParametersToString("%1OptionForDisplayingPriceTypes",Item.BookmarkName);
		FormItem = Items.Insert(TagName, Type("FormField"),FormGroup,InsertBefore_);
		
		FormItem.Type = FormFieldType.RadioButtonField;
		FormItem.DataPath = FormAttributeName;
		FormItem.ColumnsCount = 2;
		FormItem.TitleLocation = FormItemTitleLocation.None;
		FormItem.ChoiceList.Clear();
		FormItem.ChoiceList.Add("All", NStr("vi = 'Tất cả';
											|ru = 'Все';
											|en = 'All'; fa = 'همه';
											|it = 'Tutti';
											|pl = 'Wszystkie';
											|tr = 'Tümü'"));
		FormItem.ChoiceList.Add("", NStr("vi = 'Nơi có hiệu lực';
										|ru = 'Где действует';
										|en = 'Where valid'; fa = 'محل اعتبار';
										|it = 'Dove è valido';
										|pl = 'Gdzie obowiązuje';
										|tr = 'Aktif durumda'"));
		FormItem.SetAction("OnChange","OptionForDisplayingPriceTypesWhenChanging");
		
		// Command panel
		If InsertBefore_ = Undefined Then
			ElementType = "FormGroup";
			TagName = StringFunctionsClientServer.SubstituteParametersToString("%1PanelUsage",Item.BookmarkName);
			ItemCommandBar = Items.Insert(TagName, Type(ElementType),FormGroup,InsertBefore_);
			ItemCommandBar.Type = FormGroupType.CommandBar;
		Else
			ItemCommandBar = InsertBefore_;
		EndIf; 
		
		// Submenu buttons
		TagName = StringFunctionsClientServer.SubstituteParametersToString("%1SetStatus",Item.BookmarkName);
		InstallSubmenuElement = Items.Insert(TagName, Type("FormGroup"),ItemCommandBar);
		InstallSubmenuElement.Type = FormGroupType.Popup;
		InstallSubmenuElement.Title = NStr("vi = 'Thay đổi';
											|ru = 'Изменить';
											|en = 'Edit'; fa = 'ویرایش';
											|it = 'Modificare';
											|pl = 'Edit';
											|tr = 'Değiştir'");
		
		If Not Item.EditRight Then
			Continue;
		EndIf;
			
		If Item.BookmarkName = Items.GroupWarehouses.Name Then
			
			// Submenu buttons
			CommandTypeOfPrice = "Retail_2";
			TagName = StringFunctionsClientServer.SubstituteParametersToString("%1%2",Item.BookmarkName,CommandTypeOfPrice);
			PriceViewSubmenuElement = Items.Add(TagName, Type("FormGroup"),InstallSubmenuElement);
			PriceViewSubmenuElement.Type = FormGroupType.Popup;
			PriceViewSubmenuElement.Title = NStr("vi = 'Bán lẻ';
												|ru = 'Розничные';
												|en = 'Retail price type'; fa = 'نوع قیمت خرده‌فروشی';
												|it = 'Розничные';
												|pl = 'Retail price type';
												|tr = 'Perakendeler'");
			
			NamesOfStatusSettingCommands = NamesOfStatusSettingCommands(CommandTypeOfPrice, Item.Scope);
			
			TagName = StringFunctionsClientServer.SubstituteParametersToString(
				"%1%2SetStatusValid",Item.BookmarkName,CommandTypeOfPrice);
			SubmenuElementIsValid = Items.Add(TagName, Type("FormButton"),PriceViewSubmenuElement);
			SubmenuElementIsValid.Type = FormButtonType.CommandBarButton;
			SubmenuElementIsValid.Title = NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Установить';
												|pl = 'Set';
												|tr = 'Yapılandır'");
			SubmenuElementIsValid.CommandName = NamesOfStatusSettingCommands.Valid;
			
			TagName = StringFunctionsClientServer.SubstituteParametersToString(
				"%1%2SetTheStatusNotValid",Item.BookmarkName,CommandTypeOfPrice);
			SubmenuElementHasNoEffect = Items.Add(TagName, Type("FormButton"),PriceViewSubmenuElement);
			SubmenuElementHasNoEffect.Type = FormButtonType.CommandBarButton;
			SubmenuElementHasNoEffect.Title = NStr("vi = 'Xóa';
													|ru = 'Очистить';
													|en = 'Clear'; fa = 'پاک کردن';
													|it = 'Очистить';
													|pl = 'Clear';
													|tr = 'Temizle'");
			SubmenuElementHasNoEffect.CommandName = NamesOfStatusSettingCommands.NotValid;
		
			// Submenu buttons
			CommandTypeOfPrice = "Accounting_0";
			TagName = StringFunctionsClientServer.SubstituteParametersToString("%1%2",Item.BookmarkName,CommandTypeOfPrice);
			PriceViewSubmenuElement = Items.Add(TagName, Type("FormGroup"),InstallSubmenuElement);
			PriceViewSubmenuElement.Type = FormGroupType.Popup;
			PriceViewSubmenuElement.Title = NStr("vi = 'Kế toán';
												|ru = 'Учетные';
												|en = 'Accounting price type'; fa = 'نوع قیمت حسابداری';
												|it = 'Учетные';
												|pl = 'Accounting price type';
												|tr = 'Muhasebe'");
			
			NamesOfStatusSettingCommands = NamesOfStatusSettingCommands(CommandTypeOfPrice, Item.Scope);
			
			TagName = StringFunctionsClientServer.SubstituteParametersToString(
				"%1%2SetStatusValid",Item.BookmarkName,CommandTypeOfPrice);
			SubmenuElementIsValid = Items.Add(TagName, Type("FormButton"),PriceViewSubmenuElement);
			SubmenuElementIsValid.Type = FormButtonType.CommandBarButton;
			SubmenuElementIsValid.Title = NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Установить';
												|pl = 'Set';
												|tr = 'Yapılandır'");
			SubmenuElementIsValid.CommandName = NamesOfStatusSettingCommands.Valid;
			
			TagName = StringFunctionsClientServer.SubstituteParametersToString(
				"%1%2SetTheStatusNotValid",Item.BookmarkName,CommandTypeOfPrice);
			SubmenuElementHasNoEffect = Items.Add(TagName, Type("FormButton"),PriceViewSubmenuElement);
			SubmenuElementHasNoEffect.Type = FormButtonType.CommandBarButton;
			SubmenuElementHasNoEffect.Title = NStr("vi = 'Xóa';
													|ru = 'Очистить';
													|en = 'Clear'; fa = 'پاک کردن';
													|it = 'Очистить';
													|pl = 'Clear';
													|tr = 'Temizle'");
			SubmenuElementHasNoEffect.CommandName = NamesOfStatusSettingCommands.NotValid;
			
		Else
			
			If Item.BookmarkName = Items.StoreFormatsGroup.Name Then
				CommandTypeOfPrice = "Retail_2";
			Else				
				CommandTypeOfPrice = "Accounting_0";
			EndIf; 
			
			NamesOfStatusSettingCommands = NamesOfStatusSettingCommands(CommandTypeOfPrice, Item.Scope);
			
			TagName = StringFunctionsClientServer.SubstituteParametersToString("%1SetStatusValid",Item.BookmarkName);
			SubmenuElementIsValid = Items.Add(TagName, Type("FormButton"),InstallSubmenuElement);
			SubmenuElementIsValid.Type = FormButtonType.CommandBarButton;
			SubmenuElementIsValid.Title = NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Установить';
												|pl = 'Set';
												|tr = 'Yapılandır'");
			SubmenuElementIsValid.CommandName = NamesOfStatusSettingCommands.Valid;
			
			If Item.BookmarkName <> Items.StoreFormatsGroup.Name Then
				TagName = StringFunctionsClientServer.SubstituteParametersToString("%1SetTheStatusNotValid",Item.BookmarkName);
				SubmenuElementHasNoEffect = Items.Add(TagName, Type("FormButton"),InstallSubmenuElement);
				SubmenuElementHasNoEffect.Type = FormButtonType.CommandBarButton;
				SubmenuElementHasNoEffect.Title = NStr("vi = 'Xóa';
														|ru = 'Очистить';
														|en = 'Clear'; fa = 'پاک کردن';
														|it = 'Очистить';
														|pl = 'Clear';
														|tr = 'Temizle'");
				SubmenuElementHasNoEffect.CommandName = NamesOfStatusSettingCommands.NotValid;
			EndIf; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure

&AtServer
Procedure ListOfBookmarksToEmbed()
	
	MappingBookmarksToLists.Clear();
	MappingBookmarksToAddLists(
		Items.GroupWarehouses.Name, 
		Items.UseInWarehouses.Name,
		"InWarehouses", 
		AccessRight("Update", Metadata.Catalogs.Warehouses),
		Items.ControlPanelWarehousesGroup.Name,
		"OptionForDisplayingPriceTypesInWarehouses",
		Items.TheGroupDepotsChangeOfStatus.Name);
		
	MappingBookmarksToAddLists(
		Items.StoreFormatsGroup.Name,
		Items.UseInStoreFormats.Name,
		"InStoreFormats",
		AccessRight("Update", Metadata.Catalogs.StoreFormats),
		Items.ControlPanelStoreFormatsGroup.Name,
		"OptionForDisplayingPriceTypesInStoreFormats",
		Items.GroupStoreFormatsChangingTheStatus.Name);
		
	MappingBookmarksToAddLists(
		Items.PartnersGroup.Name,
		Items.UseInPartners.Name,
		"InThePartner",
		AccessRight("Update", Metadata.Catalogs.Partners),
		Items.ControlPanelGroupPartners.Name,
		"OptionForDisplayingPriceTypesInPartners",
		Items.PartnersGroupStatusChange.Name);
		
	MappingBookmarksToAddLists(
		Items.AgreementGroup.Name,
		Items.UseInCustomerAgreements_.Name,
		"IntoAnAgreement",
		AccessRight("Update", Metadata.Catalogs.TermsOfSale),
		Items.ControlPanelAgreementGroup.Name,
		"OptionForDisplayingPriceTypesInAgreements",
		Items.AgreementGroupStatusChange.Name);
	
EndProcedure

&AtServer
Procedure MappingBookmarksToAddLists(BookmarkName, ListName, Scope, EditRight, NameControlPanel, NameOptionForDisplayingPriceTypes, GroupNameChangeStatus);
	
	NewRow = MappingBookmarksToLists.Add();
	NewRow.BookmarkName 	= BookmarkName; 
	NewRow.ListName 		= ListName; 
	NewRow.Scope = Scope;
	NewRow.EditRight  = EditRight;
	NewRow.NameControlPanel = NameControlPanel;
	NewRow.NameOptionForDisplayingPriceTypes = NameOptionForDisplayingPriceTypes;
	NewRow.GroupNameChangeStatus = GroupNameChangeStatus;
	
EndProcedure

&AtClient
Procedure ChangingDynamicListFilter(MatchingBookmarks)

	If MatchingBookmarks = Undefined Then
		Return;
	EndIf; 
	
	CommonClientServer.SetDynamicListFilterItem(
		ThisObject[MatchingBookmarks.ListName],	
		"Status",
		PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid"),
		DataCompositionComparisonType.Equal,
		,
		OptionForDisplayingPriceTypes <> "All");
	
EndProcedure

// Description get bookmark matching
// 
// Parameters:
// 	SearchColumn_ - String - name of the search column
// 	SearchValue - String - the search value
// Returns:
// 	Undefined, Structure - LongDesc:
// * BookmarkName - String - Bookmark name
// * ListName - String - list name
// * Scope - String - Scope
// * NameControlPanel - String - Name of the Control Panel group
// * NameOptionForDisplayingPriceTypes - String - The name of the details of the options for displaying the types of prices
&AtClient
Function GetBookmarkContent(Val SearchColumn_ = "BookmarkName", Val SearchValue = "")
	MatchingBookmarks = Undefined;
	
	If SearchValue = "" Then
		If SearchColumn_ = "BookmarkName" Then
			CurrentPage = Items.GroupPages.CurrentPage;
			If CurrentPage <>  Undefined Then
				SearchValue = CurrentPage.Name;
			EndIf;	
		EndIf;	
	EndIf; 
		
	If SearchValue <> Undefined Then
		Filter = New Structure(SearchColumn_, SearchValue);
		FoundItems1 = MappingBookmarksToLists.FindRows(Filter);
		If FoundItems1.Count() > 0 Then
			MatchingBookmarks = New Structure("BookmarkName, ListName, Scope, NameControlPanel, NameOptionForDisplayingPriceTypes");
			FillPropertyValues(MatchingBookmarks, FoundItems1[0]);
		EndIf;
	EndIf;
	
	Return MatchingBookmarks
	
EndFunction

// Description get bookmark matching
// 
// Parameters:
// 	SearchColumn_ - String - name of the search column
// 	SearchValue - String - the search value
// Returns:
// 	Undefined, Structure - LongDesc:
// * BookmarkName - String - Bookmark name
// * ListName - String - list name
// * Scope - String - Scope
// * NameControlPanel - String - Name of the Control Panel group
// * NameOptionForDisplayingPriceTypes - String - The name of the details of the options for displaying the types of prices
&AtServer
Function GetBookmarkContentServer(Val SearchColumn_ = "BookmarkName", Val SearchValue)
	
	MatchingBookmarks = Undefined;
	
	If SearchValue <> Undefined Then
		Filter = New Structure(SearchColumn_, SearchValue);
		FoundItems1 = MappingBookmarksToLists.FindRows(Filter);
		If FoundItems1.Count() > 0 Then
			MatchingBookmarks = New Structure("BookmarkName, ListName, Scope, NameControlPanel, NameOptionForDisplayingPriceTypes");
			FillPropertyValues(MatchingBookmarks, FoundItems1[0]);
		EndIf;
	EndIf;
	
	Return MatchingBookmarks
	
EndFunction


// Parameters:
// 	PriceKindName - String - LongDesc
// 	Scope - String - LongDesc
// Returns:
// 	Structure: - Will contain the keys:
// 		* Valid - String -
// 		* NotValid - String -
&AtServer
Function NamesOfStatusSettingCommands(PriceKindName, Scope)
	
	Result = New Structure();
	Result.Insert("Valid");
	Result.Insert("NotValid");
	
	If PriceKindName = "Retail_2" Then
		If Scope = "InWarehouses" Then
			Result.Valid = Commands.SetTheStatusActiveRetailInWarehouses.Name;
			Result.NotValid = Commands.ToSetTheStatusNotValidOnRetailWarehouses.Name;
		ElsIf Scope = "InStoreFormats" Then
			Result.Valid = Commands.SetTheStatusValidRetailInStoreFormats.Name;
			Result.NotValid = Commands.SetTheStatusNotValidRetailInStoreFormats.Name;
		EndIf;
	ElsIf PriceKindName = "Accounting_0" Then
		If Scope = "InWarehouses" Then
			Result.Valid = Commands.SetTheStatusToValidAccountInTheWarehouses.Name;
			Result.NotValid = Commands.SetTheStatusOfTheAccountIsNotValidInTheWarehouses.Name;
		ElsIf Scope = "IntoAnAgreement" Then
			Result.Valid = Commands.SetTheStatusToValidAccountInTheAgreements.Name;
			Result.NotValid = Commands.SetTheStatusNotValidAccountingInAgreements.Name;
		ElsIf Scope = "InThePartner" Then
			Result.Valid = Commands.SetTheStatusOfTheAccountInPartnersIsValid.Name;
			Result.NotValid = Commands.SetTheStatusNotValidAccountInPartners.Name;
		EndIf;
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region GeneratingQueryTextsForRedefinedLists

&AtServerNoContext
Function DynamicListQueryText1(ListParameters)
	
	RequestText = "SELECT ALLOWED
	|	COUNT(DISTINCT T.Ref) AS QuantitySet,
	|	T.PricesKind AS PriceKind
	|INTO UseInWarehouses
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		T.RetailPriceType AS PricesKind
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		T.RetailPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT
	|		T.Ref,
	|		T.AccountingPriceType
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		T.AccountingPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT
	|		T.Ref,
	|		T.SpecialPriceType
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		T.SpecialPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)) AS T
	|GROUP BY
	|	T.PricesKind
	|;
	|SELECT * FROM &StoreFormatsTable;
	|SELECT * FROM &PartnersTable;
	|SELECT * FROM &AgreementsTable;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(T.NumberOfWarehousesTotal) AS NumberOfWarehousesTotal,
	|	MAX(T.NumberOfStoreFormatsTotal) AS NumberOfStoreFormatsTotal,
	|	MAX(T.NumberOfPartnersTotal) AS NumberOfPartnersTotal,
	|	MAX(T.NumberOfAgreementsTotal) AS NumberOfAgreementsTotal
	|INTO TotalObjectCount
	|FROM
	|	(SELECT
	|		COUNT(T.Ref) AS NumberOfWarehousesTotal,
	|		0 AS NumberOfStoreFormatsTotal,
	|		0 AS NumberOfPartnersTotal,
	|		0 AS NumberOfAgreementsTotal
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		NOT T.DeletionMark
	|		AND NOT T.IsFolder
	|	
	|	UNION
	|	
	|	SELECT
	|		0,
	|		COUNT(T.Ref),
	|		0,
	|		0
	|	FROM
	|		Catalog.StoreFormats AS T
	|	WHERE
	|		NOT T.DeletionMark
	|		AND NOT T.IsFolder
	|	
	|	UNION
	|	
	|	SELECT
	|		0,
	|		0,
	|		COUNT(T.Ref),
	|		0
	|	FROM
	|		Catalog.Partners AS T
	|	WHERE
	|		NOT T.DeletionMark
	|	
	|	UNION
	|	
	|	SELECT
	|		0,
	|		0,
	|		0,
	|		&NumberOfCustomerAgreements
	|	FROM
	|		Catalog.TermsOfSale AS T
	|	WHERE
	|		NOT T.DeletionMark
	|) AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogTypesOfPrices.Ref AS PriceKind,
	|	ISNULL(UseInWarehouses.QuantitySet, 0) AS NumberOfWarehouses,
	|	ISNULL(TotalObjectCount.NumberOfWarehousesTotal, 0) AS NumberOfWarehousesTotal,
	|	&FormatsAndFields,
	|	&PartnersOfField,
	|	&FieldConventions,
	|	CatalogTypesOfPrices.IsFolder AS IsFolder,
	|	CatalogTypesOfPrices.Parent AS Parent
	|FROM
	|	Catalog.TypesOfPrices AS CatalogTypesOfPrices
	|		LEFT JOIN UseInWarehouses AS UseInWarehouses
	|		ON CatalogTypesOfPrices.Ref = UseInWarehouses.PriceKind
	|		{LEFT JOIN TotalObjectCount AS TotalObjectCount
	|		ON (TRUE)}
	|		LEFT JOIN &StoreFormatsConnection ON TRUE
	|		LEFT JOIN &PartnersConnection ON TRUE
	|		LEFT JOIN &ConnectionAgreements ON TRUE
	|WHERE
	|	CatalogTypesOfPrices.Ref IN (&ReferencesArrray)
	|";
	
	FoundParameter = ListParameters.Find("UseStoreFormats");
	UsageFlag = ?(FoundParameter = Undefined, False, FoundParameter.Value);
	AddTextToRequestInformationOnStoreFormats(RequestText, UsageFlag);

	FoundParameter = ListParameters.Find("UsePartners");
	UsageFlag = ?(FoundParameter = Undefined, False, FoundParameter.Value);
	AddTextAndPartnerInformationToRequest(RequestText, UsageFlag);

	FoundParameter = ListParameters.Find("ToUseTermsOfSales");
	UsageFlag = ?(FoundParameter = Undefined, False, FoundParameter.Value);
	AddTextAndAgreementInformationToRequest(RequestText, UsageFlag);
	
	Return RequestText;
	
EndFunction

&AtServerNoContext
Procedure AddTextToRequestInformationOnStoreFormats(RequestText, UsageFlag)
	
	If UsageFlag Then
		
		StoreFormatsTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT T.Ref) AS QuantitySet,
		|	T.PriceKind AS PriceKind
		|INTO UseInStoreFormats
		|FROM
		|	(SELECT
		|		T.Ref AS Ref,
		|		T.RetailPriceType AS PriceKind
		|	FROM
		|		Catalog.StoreFormats AS T
		|	WHERE
		|		T.RetailPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.Ref,
		|		T.SpecialPriceType
		|	FROM
		|		Catalog.StoreFormats AS T
		|	WHERE
		|		T.SpecialPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)) AS T
		|GROUP BY
		|	T.PriceKind
		|;
		|";
		
		FormatsAndFields = "
		|	ISNULL(UseInStoreFormats.QuantitySet, 0) AS NumberOfStoreFormats,
		|	ISNULL(TotalObjectCount.NumberOfStoreFormatsTotal, 0) AS NumberOfStoreFormatsTotal,";
		
		StoreFormatsConnection = "		
		|		LEFT JOIN UseInStoreFormats AS UseInStoreFormats
		|		ON CatalogTypesOfPrices.Ref = UseInStoreFormats.PriceKind";	
		
	Else
		StoreFormatsTable    = "";
		StoreFormatsConnection = "";
		FormatsAndFields       = "
		|	0 AS NumberOfStoreFormats,
		|	0 AS NumberOfStoreFormatsTotal,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&FormatsAndFields,", FormatsAndFields);
	RequestText = StrReplace(RequestText, "SELECT * FROM &StoreFormatsTable;", StoreFormatsTable);
	RequestText = StrReplace(RequestText, "LEFT JOIN &StoreFormatsConnection ON TRUE", StoreFormatsConnection);
	
EndProcedure

&AtServerNoContext
Procedure AddTextAndPartnerInformationToRequest(RequestText, UsageFlag)
	
	If UsageFlag Then
		
		PartnersTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT T.Ref) AS QuantitySet,
		|	T.PriceKind AS PriceKind
		|INTO UseInPartners
		|FROM
		|	(SELECT
		|		T.Ref AS Ref,
		|		T.PricesKind AS PriceKind
		|	FROM
		|		Catalog.Partners AS T
		|	WHERE
		|		T.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.Ref,
		|		T.SpecialPriceType
		|	FROM
		|		Catalog.Partners AS T
		|	WHERE
		|		T.SpecialPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)) AS T
		|GROUP BY
		|	T.PriceKind
		|;
		|";
			
		PartnersOfField = "
		|	ISNULL(UseInPartners.QuantitySet, 0) AS NumberOfPartners,
		|	ISNULL(TotalObjectCount.NumberOfPartnersTotal, 0) AS NumberOfPartnersTotal,";
		
		PartnersConnection = "		
		|		LEFT JOIN UseInPartners AS UseInPartners
		|		ON CatalogTypesOfPrices.Ref = UseInPartners.PriceKind";	
		
	Else
		
		PartnersTable    = "";
		PartnersConnection = "";
		PartnersOfField       = "
		|	0 AS NumberOfPartners,
		|	0 AS NumberOfPartnersTotal,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&PartnersOfField,", PartnersOfField);
	RequestText = StrReplace(RequestText, "SELECT * FROM &PartnersTable;", PartnersTable);
	RequestText = StrReplace(RequestText, "LEFT JOIN &PartnersConnection ON TRUE", PartnersConnection);
	
EndProcedure

&AtServerNoContext
Procedure AddTextAndAgreementInformationToRequest(RequestText, UsageFlag)
	
	If UsageFlag Then
		
		NumberOfCustomerAgreements    = "COUNT(T.Ref)";
		
		AgreementsTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT T.Ref) AS QuantitySet,
		|	T.PriceKind AS PriceKind
		|INTO UseInCustomerAgreements
		|FROM
		|	(SELECT
		|		T.Ref AS Ref,
		|		T.PricesKind AS PriceKind
		|	FROM
		|		Catalog.TermsOfSale AS T
		|	WHERE
		|		T.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.Ref,
		|		T.SpecialPriceType
		|	FROM
		|		Catalog.TermsOfSale AS T
		|	WHERE
		|		T.SpecialPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)) AS T
		|GROUP BY
		|	T.PriceKind
		|;
		|";
		
		FieldConventions = "
		|	ISNULL(UseInCustomerAgreements.QuantitySet, 0) AS NumberOfAgreements,
		|	ISNULL(TotalObjectCount.NumberOfAgreementsTotal, 0) AS NumberOfAgreementsTotal,";
		
		ConnectionAgreements = "		
		|		LEFT JOIN UseInCustomerAgreements AS UseInCustomerAgreements
		|		ON CatalogTypesOfPrices.Ref = UseInCustomerAgreements.PriceKind";	
		
	Else
		NumberOfCustomerAgreements    = "0";
		AgreementsTable    = "";
		ConnectionAgreements = "";
		FieldConventions       = "
		|	0 AS NumberOfAgreements,
		|	0 AS NumberOfAgreementsTotal,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&NumberOfCustomerAgreements", NumberOfCustomerAgreements);
	RequestText = StrReplace(RequestText, "&FieldConventions,", FieldConventions);
	RequestText = StrReplace(RequestText, "SELECT * FROM &AgreementsTable;", AgreementsTable);
	RequestText = StrReplace(RequestText, "LEFT JOIN &ConnectionAgreements ON TRUE", ConnectionAgreements);
	
EndProcedure

&AtServer
Function DynamicListRequestTextUseInCustomerAgreements()
	
	QueryText = 
	"SELECT
	|	TermsOfSale.Ref AS Terms,
	|	TermsOfSale.Status AS AgreementStatus,
	|	TermsOfSale.Partner AS Partner,
	|	ISNULL(CustomerAgreementsActions.Status, VALUE(Enum.StatusesOfPriceTypeValidity.NotValid)) AS Status,
	|	CASE
	|		WHEN TermsOfSale.SpecialPriceType = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsAnIndividualTypeOfPrices,
	|	TermsOfSale.PricesKind,
	|	CASE
	|		WHEN TermsOfSale.Standard_
	|			THEN 0
	|		ELSE 1
	|	END AS TheIndexOfTheImageIsTypical,
	|	TermsOfSale.Organization AS Organization,
	|	TermsOfSale.Counterparty AS Counterparty,
	|	TermsOfSale.PartnersSegment AS PartnersSegment
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN (SELECT
	|			CustomerAgreementsActions.Ref AS Ref,
	|			CASE
	|				WHEN CustomerAgreementsActions.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				AND CustomerAgreementsActions.SpecialPriceType = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|					THEN VALUE(Enum.StatusesOfPriceTypeValidity.NotValid)
	|				ELSE VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
	|			END AS Status
	|		FROM
	|			Catalog.TermsOfSale AS CustomerAgreementsActions
	|		WHERE
	|			CustomerAgreementsActions.PricesKind = &PricesKind
	|			OR CustomerAgreementsActions.SpecialPriceType = &PricesKind) AS CustomerAgreementsActions
	|		ON TermsOfSale.Ref = CustomerAgreementsActions.Ref";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region OverridingDynamicLists

&AtServer
Procedure OverridePropertiesOfDynamicLists()
	
	OverridePropertiesOfUseListInCustomerAgreements();
	OverridePropertiesOfMainList();
	
EndProcedure

&AtServer
Procedure OverridePropertiesOfUseListInCustomerAgreements()
	
	If ToUseTermsOfSales Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText                 = DynamicListRequestTextUseInCustomerAgreements();
		ListProperties.MainTable              = "Catalog.TermsOfSale";
		ListProperties.DynamicDataRead = True;
		Common.SetDynamicListProperties(Items.UseInCustomerAgreements_, ListProperties);
	EndIf;
	
EndProcedure

&AtServer
Procedure OverridePropertiesOfMainList()

	CommonClientServer.SetDynamicListParameter(
		List,
		"UseSeveralWarehouses",
		UseSeveralWarehouses);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"UseStoreFormats",
		UseStoreFormats);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"UsePartners",
		UsePartners);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"ToUseTermsOfSales",
		ToUseTermsOfSales);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetFOSettings()
		
	Items.AgreementGroup.Visible							= ToUseTermsOfSales;
	Items.IntoAnAgreement.Visible 							= ToUseTermsOfSales;
	Items.ControlPanelAgreementGroup.Visible 		= ToUseTermsOfSales;
	Items.GroupWarehouses.Visible								= UseSeveralWarehouses;
	Items.InWarehouses.Visible								= UseSeveralWarehouses;
	Items.ControlPanelWarehousesGroup.Visible				= UseSeveralWarehouses;
	Items.Group1.Visible									= UseSeveralWarehouses;
	Items.StoreFormatsGroup.Visible					= UseStoreFormats;
	Items.InStoreFormats.Visible						= UseStoreFormats;
	Items.ControlPanelStoreFormatsGroup.Visible	= UseStoreFormats;
	Items.Group8.Visible									= UseStoreFormats;
	Items.PartnersGroup.Visible							= UsePartners;
	Items.InThePartner.Visible								= UsePartners;
	Items.ControlPanelGroupPartners.Visible			= UsePartners;
	Items.Group7.Visible									= UsePartners;
	Items.LabelInPartners.Visible						= UsePartners;
	Items.TeamInPartners1.Visible						= UsePartners;
	Items.TeamInPartners2.Visible						= UsePartners;
	Items.TeamInPartners4.Visible						= UsePartners;
	
	Items.TeamInAgreements1.Visible						= ToUseTermsOfSales;
	Items.TheInscriptionOfTheAgreements.Visible						= ToUseTermsOfSales;
	Items.TeamInAgreements2.Visible						= ToUseTermsOfSales;
	Items.TeamInAgreements3.Visible						= ToUseTermsOfSales;
	Items.Group9.Visible									= ToUseTermsOfSales;
	
	DestinationSelectionList = Items.PurposeSelection.ChoiceList;
	DestinationSelectionList.Clear();	
	DestinationSelectionList.Add(PredefinedValue("Enum.PriceTypesAssignment.Shared"), NStr("vi = 'tất cả';
																							|ru = 'всех';
																							|en = 'all'; fa = 'همه';
																							|it = 'tutti';
																							|pl = 'wszystkich';
																							|tr = 'tüm'"));

	If UseSeveralWarehouses Then
		DestinationSelectionList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForWarehouse"), NStr("vi = 'kho bãi';
																											|ru = 'склада';
																											|en = 'warehouse'; fa = 'انبار';
																											|it = 'magazzino';
																											|pl = 'magazynu';
																											|tr = 'ambar kapsamında'"));
	EndIf;
	
	If UseStoreFormats Then
		DestinationSelectionList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForStoreFormat"), NStr("vi = 'khuôn dạng cửa hàng';
																												|ru = 'формата магазинов';
																												|en = 'retail format'; fa = 'قالب خرده‌فروشی';
																												|it = 'del formato del punto vendita';
																												|pl = 'formatu sklepów';
																												|tr = 'mağaza formatı kapsamında'"));
	EndIf;
	
	If UsePartners Then
		DestinationSelectionList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForPartner"), NStr("vi = 'bạn hàng';
																											|ru = 'партнера';
																											|en = 'partner'; fa = 'شریک تجاری';
																											|it = 'del partner';
																											|pl = 'partnera';
																											|tr = 'iş ortağı'"));
	EndIf;
	
	If ToUseTermsOfSales Then
		DestinationSelectionList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForTermsOfSales"), NStr("vi = 'thỏa thuận';
																												|ru = 'соглашения';
																												|en = 'terms of sale'; fa = 'terms of sale';
																												|it = 'dell''accordo';
																												|pl = 'porozumienia';
																												|tr = 'Anlaşmalar'"));
	EndIf;
	
	UsageSelectionList = Items.UseFilter.ChoiceList;
	UsageSelectionList.Clear();
	UsageSelectionList.Add("UseWhileSellingToCustomers", NStr("vi = 'tất cả doanh thu';
																|ru = 'всех продажах';
																|en = 'all sales'; fa = 'all sales';
																|it = 'di tutte le vendite';
																|pl = 'wszystkich operacji sprzedaży';
																|tr = 'tüm satışlarda'"));
	UsageSelectionList.Add("UseForWholesaleToCustomers", NStr("vi = 'bán buôn';
																|ru = 'оптовой продаже';
																|en = 'wholesale'; fa = 'wholesale';
																|it = 'Per la vendita all''ingrosso';
																|pl = 'sprzedaży hurtowej';
																|tr = 'toptan satışta'"));
	UsageSelectionList.Add("UseForRetailSalesToCustomers", NStr("vi = 'bán lẻ';
																|ru = 'розничной продаже';
																|en = 'retail sales'; fa = 'retail sales';
																|it = 'Per la vendita al dettaglio';
																|pl = 'sprzedaży detalicznej';
																|tr = 'perakende satışta'"));

	If UseForIntercompanySales Then
		UsageSelectionList.Add("UseForIntercompanySales", NStr("vi = 'chuyển giao hàng hóa giữa các doanh nghiệp';
																|ru = 'передаче между организациями';
																|en = 'intercompany sales'; fa = 'intercompany sales';
																|it = 'Per il trasferimento tra organizzazioni';
																|pl = 'przekazaniu między firmami';
																|tr = 'iş yerleri arasında transfer ederken'"));
	EndIf;
	If UseWhileTransferringProductsToMaterialProvider Then
		UsageSelectionList.Add("UseWhileTransferringProductsToMaterialProvider", NStr("vi = 'chuyển thành phẩm cho người đặt gia công';
																						|ru = 'передаче продукции давальцу';
																						|en = 'transfers to material provider'; fa = 'transfers to material provider';
																						|it = 'Per il trasferimento della produzione al prestatore';
																						|pl = 'przekazaniu produkcji właścicielowi surowców';
																						|tr = 'imal edilen ürünlerin tedarikçiye transferinde'"));
	EndIf;
	If UseProduction Then
		UsageSelectionList.Add("UseForIssuingProductsWorksAndServicesAtFixedCost", NStr("vi = 'xuất xưởng thành phẩm';
																						|ru = 'выпуске продукции';
																						|en = 'product release'; fa = 'product release';
																						|it = 'al rilascio del prodotto';
																						|pl = 'wyprodukowanie produkcji';
																						|tr = 'imal edilen ürün çıkışında'"));
	EndIf;
	
	PriceManagementSystemServerCall.SetPropertiesOfSceneryInformingAboutRemovalOfPricingVersion20(Items);
	
EndProcedure

&AtServer
Procedure ReadFO()
		
	UseSeveralWarehouses        		= GetFunctionalOption("UseSeveralWarehouses")
	                                      		  And AccessRight("Read", Metadata.Catalogs.Warehouses);
	
	UseStoreFormats        		= GetFunctionalOption("UseStoreFormats")
	                                              And AccessRight("Read", Metadata.Catalogs.StoreFormats);
	
	ToUseTermsOfSales 			= GetFunctionalOption("ToUseTermsOfSales")
	                                      		  And AccessRight("Read", Metadata.Catalogs.TermsOfSale);
	
	UsePartners               		= GetFunctionalOption("UsePartnersAndCounterparties")
	                                      		  And AccessRight("Read", Metadata.Catalogs.Partners)
	                                      		  And Not ToUseTermsOfSales;

	UseForIntercompanySales	= GetFunctionalOption("UseCustomerInvoiceIntercompany");

	UseWhileTransferringProductsToMaterialProvider	= False; 
	UseWhileTransferringProductsToMaterialProvider	=
		UseWhileTransferringProductsToMaterialProvider
		Or GetFunctionalOption("UseTollManufacturing2_5");
	UseProduction					= GetFunctionalOption("UseProduction");

	UsePriceManagementSystem25				= PriceManagementSystemServerCall.UsePriceManagementSystem25();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_ConstantsSet" Then
		If Source =	"UseStoreFormats" 
			Or Source =	"UseSeveralWarehouses"
			Or Source =	"UsePartnersAndCounterparties"
			Or Source =	"ToUseTermsOfSales"
			Or Source =	"UseProduction"
			Or Source =	"UseCustomerInvoiceIntercompany"
			Or Source =	"UseTollManufacturing2_5" Then
			
			ReadFO();
			SetFOSettings();
			
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function InitializingDataStructureByPriceType()
	Result = New Structure;
	Result.Insert("PricesKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	Result.Insert("Purpose", PredefinedValue("Enum.PriceTypesAssignment.Shared"));
	Result.Insert("UseForRetailSalesToCustomers", False);
	Result.Insert("NumberOfWarehouses", 0);
	Result.Insert("NumberOfWarehousesTotal", 0);
	Result.Insert("NumberOfStoreFormats", 0);
	Result.Insert("NumberOfStoreFormatsTotal", 0);
	Result.Insert("NumberOfPartners", 0);
	Result.Insert("NumberOfPartnersTotal", 0);
	Result.Insert("NumberOfAgreements", 0);
	Result.Insert("NumberOfAgreementsTotal", 0);
	
	Return Result;
EndFunction
	
// Generates information lines on the use of price types in the context of types of action sources.
//
// Parameters:
//  DataOnTypeOfPrices  - Structure - contains information about using the price type. For more information about
//            structure fields, see the description of the structure Initializationdannypoviducen function.
//
&AtServer
Procedure GenerateInformationAboutNumberOfPriceTypesUsed(DataOnTypeOfPrices)

	TitleTemplate1          = NStr("vi = '(%1 trong số %2)';
									|ru = '(%1 из %2)';
									|en = '(%1 out of %2).'; fa = '(%1 out of %2).';
									|it = '(%1 da %2)';
									|pl = '(%1 z %2)';
									|tr = '(%2 üzerinden %1)'");

	If Not DataOnTypeOfPrices = Undefined Then
		
		If DataOnTypeOfPrices.NumberOfWarehousesTotal > 0 Then
			
			InscriptionQuantityInWarehouses = StrTemplate(TitleTemplate1, 
										DataOnTypeOfPrices.NumberOfWarehouses,
										DataOnTypeOfPrices.NumberOfWarehousesTotal);
 										 
		EndIf;
		
		If DataOnTypeOfPrices.NumberOfStoreFormatsTotal > 0 Then
			
			LabelQuantityInStoreFormats = StrTemplate(TitleTemplate1, 
				                         DataOnTypeOfPrices.NumberOfStoreFormats,
				                         DataOnTypeOfPrices.NumberOfStoreFormatsTotal);
 										 
		EndIf;
		
		If DataOnTypeOfPrices.NumberOfPartnersTotal > 0 Then
			
			InscriptionQuantityInPartners = StrTemplate(TitleTemplate1, 
				                         DataOnTypeOfPrices.NumberOfPartners,
				                         DataOnTypeOfPrices.NumberOfPartnersTotal);
 										 
		EndIf;
		
		If DataOnTypeOfPrices.NumberOfAgreementsTotal > 0 Then
			
			InscriptionQuantityInAgreements = StrTemplate(TitleTemplate1, 
				                         DataOnTypeOfPrices.NumberOfAgreements,
				                         DataOnTypeOfPrices.NumberOfAgreementsTotal);
 										 
		EndIf;
			
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion
