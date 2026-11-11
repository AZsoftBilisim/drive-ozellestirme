#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var Changed_Price; // It is used in the mechanisms of event handlers of the tabular part of the Goods

&AtClient
Var QuestionIsDisplayed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	OptionToChangeThePrice	= 1;
	
	SetConditionalAppearance();
	
	SettingPricesServer.LoadDefaultSelectionSettings(ThisObject);
	
	Date = EndOfDay(CurrentSessionDate());
	FormCode = "Processing_PriceList_Form";
	
	FlagOfOpeningAForm = True;
	
	AdditionalColumnName = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	
	UsePriceGroups              = GetFunctionalOption("UsePriceGroups");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	UseSeveralPriceTypes          = GetFunctionalOption("UseSeveralPriceTypes");
	UsePriceManagementSystem25          = PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);
	UseIntegrationWithYandexMarket    = False;
	UseIntegrationWithOzon            = False;
	CurrentDate = CurrentSessionDate();
	
	
	FillInCharacteristicPricesByProductsAutomatically = True;
	
	TypesOfPrices = Undefined;
	If Parameters.Property("TypesOfPrices") Then
		TypesOfPrices = Parameters.TypesOfPrices;
	EndIf;
	
	TableOfPriceTypes = Undefined;
	SavedSettings = SettingPricesClientServer.NewFormSettingsStructure();
	SavedSettingsFromStorage = Common.CommonSettingsStorageLoad("DataProcessor.PriceList", "DataProcessor.PriceList");
	If SavedSettingsFromStorage <> Undefined Then
		FillPropertyValues(SavedSettings, SavedSettingsFromStorage);
		If SavedSettings.Property("SelectedPricesTable") And ValueIsFilled(SavedSettings.SelectedPricesTable) Then
			TableOfPriceTypes = SavedSettings.SelectedPricesTable;
		EndIf;
	EndIf;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject,TypesOfPrices,TableOfPriceTypes);
	
	If Not ValueIsFilled(Parameters.Products) And Not ValueIsFilled(TypesOfPrices) Then
		
		If ValueIsFilled(SavedSettings.ComposerSettings) Then
			SettingsComposerFilter.LoadSettings(SavedSettings.ComposerSettings);
		EndIf;
		
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		If ValueIsFilled(SavedSettings.ColumnComposerSettings) Then
			SettingsBuilderColumnSelection.LoadSettings(SavedSettings.ColumnComposerSettings);
		EndIf;
		
		If ValueIsFilled(SavedSettings.SelectedPricesTable) Then
			For Each TSRow In SelectedPrices Do
				
				PriceTypeFound = SavedSettings.SelectedPricesTable.Find(TSRow.Ref, "PriceKind");
				
				TSRow.Selected_5 = PriceTypeFound <> Undefined And Not TSRow.ProhibitedPriceType;
				
				TSRow.Edit = TSRow.Selected_5;
				
			EndDo;
		ElsIf ValueIsFilled(SavedSettings.SelectedPrices) Then
			For Each TSRow In SelectedPrices Do
				
				TSRow.Selected_5 = SavedSettings.SelectedPrices.Find(TSRow.Ref) <> Undefined
				                   And Not TSRow.ProhibitedPriceType;
				
				TSRow.Edit = TSRow.Selected_5;
			EndDo;
		EndIf;
		SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(ThisObject);
		
		If ValueIsFilled(SavedSettings.FilterParametersTable) Then
			FilterParametersTable.Load(SavedSettings.FilterParametersTable);
		EndIf;
		
		FillInDisplaySettings(SavedSettings);
		
		SelectedPrices.Sort("AddlOrderingAttribute");
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		
	Else
	
		If SelectedPrices.Count() = 1 Then
			For Each CurRow In SelectedPrices Do
				CurRow.Selected_5 = True;
			EndDo;
		Else		
			// if the selection form is opened with the nomenclature, then we limit the displayed types of prices only to those for which prices were set earlier
			If ValueIsFilled(Parameters.Products) Then
				
				ParametersOfPriceTypes = New Structure;
				ParametersOfPriceTypes.Insert("Products", 					Parameters.Products);
				ParametersOfPriceTypes.Insert("Date",							Date);
				ParametersOfPriceTypes.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
				
				ArrayOfPriceTypes = GetArrayOfPreviouslySetPriceTypesByProductType(ParametersOfPriceTypes);
				
				If ArrayOfPriceTypes.Count() > 0 Then
					For Each PriceKind In ArrayOfPriceTypes Do
						RowsArray = SelectedPrices.FindRows(New Structure("Ref", PriceKind));
						If RowsArray.Count() > 0 Then
							TableRow = RowsArray[0];
							If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
								TableRow.Selected_5 = True;
								TableRow.Edit = True;
							EndIf;	
						EndIf;
					EndDo;
				EndIf;
				
				SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(ThisObject);
			
			ElsIf ValueIsFilled(TypesOfPrices) Then
				
				If TypesOfPrices.Count() > 0 Then
					For Each PriceKind In TypesOfPrices Do
						RowsArray = SelectedPrices.FindRows(New Structure("Ref", PriceKind));
						If RowsArray.Count() > 0 Then
							TableRow = RowsArray[0];
							If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
								TableRow.Selected_5 = True;
							EndIf;	
						EndIf;
					EndDo;
				EndIf;
				
				SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(ThisObject);
				
			Else
			
				For Each TableRow In SelectedPrices Do
					If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
						TableRow.Selected_5 = True;
					EndIf;
				EndDo;
				
			EndIf;
					
		EndIf;
		
		FillInDisplaySettings(SavedSettings);

		SelectedPrices.Sort("AddlOrderingAttribute");
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		
	EndIf;
	
	If GroupingOption = Undefined Then
		GroupingOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives;
	EndIf;

	FixTheItemColumn(FixTheItemColumn);
	
	If ValueIsFilled(Parameters.Products) Then
		
		SaveAllSettings = False;
		
		SettingsComposerFilter.Settings.Filter.Items.Clear();
		
		ItemList = New ValueList;
		ItemList.Add(Parameters.Products);
		
		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Products",
			DataCompositionComparisonType.InList,
			ItemList,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
			
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		ApplySettings();
	ElsIf ValueIsFilled(TypesOfPrices) Then
		
		SaveAllSettings = False;
		
		SettingsComposerFilter.Settings.Filter.Items.Clear();

		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"PriceIsSet",
			DataCompositionComparisonType.Equal,
			True,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
		
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		ApplySettings();
		
	ElsIf Parameters.Property("PriceListEditingData") Then
		
		ApplySettings(Undefined, Parameters.PriceListEditingData);
		
	Else
		
		SaveAllSettings = True;
		ApplySettings();
		
	EndIf;
		
	ChangingProductPricingSettings = AccessRight("Update", Metadata.Documents.PriceSetup);
	PricesHistoryOfItemsAndService = AccessRight("View", Metadata.InformationRegisters.ItemsPricesOfVendor)
		Or AccessRight("View", Metadata.InformationRegisters.ItemsPrices);
		
	Items.PriceTree.ReadOnly                         = Not ChangingProductPricingSettings;
	Items.PrintRetailRevaluationView.Visible       = ChangingProductPricingSettings;
	Items.PrintSetItemPricesView.Visible = ChangingProductPricingSettings;
	Items.PrintPriceTagsView.Visible                  = ChangingProductPricingSettings;
	Items.ThePrintLabelPreview.Visible                 = ChangingProductPricingSettings;
	Items.PriceTreeContextMenuPriceChangeHistoryContext.Visible = PricesHistoryOfItemsAndService;
	
	Items.UploadCurrentPricesEdit.Enabled   = ChangingProductPricingSettings;
	Items.UploadFormFromDocumentsEditing.Enabled = ChangingProductPricingSettings;
	Items.ToCalculateTheEdit.Enabled                 = ChangingProductPricingSettings;
	Items.ToChangePricesEdit.Enabled               = ChangingProductPricingSettings;
	Items.ToCompleteThePriceChange.Enabled                    = ChangingProductPricingSettings;
	Items.CancelPriceChange.Enabled                     = ChangingProductPricingSettings;
	Items.GroupChangePricesView.Enabled               = ChangingProductPricingSettings;
	Items.PriceTree.ContextMenu.ChildItems.ChangePrices.Enabled = ChangingProductPricingSettings;
	
	Items.DownloadFromExcelView.Enabled                 = ChangingProductPricingSettings;
	Items.DownloadEditingFromExcel.Enabled           = ChangingProductPricingSettings;
	Items.FillInVATRateView.Visible                 = UsePriceManagementSystem25 And ChangingProductPricingSettings And ShowVATRate;
	Items.FillInVATRateEdit.Visible           = UsePriceManagementSystem25 And ChangingProductPricingSettings And ShowVATRate;

	Items.QuickEditGroup.Enabled             = ChangingProductPricingSettings;
	Items.DownloadFromYandexMarket.Visible                    = UseIntegrationWithYandexMarket;
	Items.DownloadFromOzon.Visible                            = UseIntegrationWithOzon;
	
	Items.ChangeValueString.TextEdit = False;
	
	HintTextPeriod = NStr("vi = 'Giới hạn thiết lập giá theo thời gian: đơn giá được thiết lập vào kỳ cụ thể,
		|sau khi kết thúc sẽ quay trở lại mức giá trước đó';
		|ru = 'Ограничивать установку цен периодом: цены устанавливаются на указанный период,
		|после окончания которого будут возвращены прежние цены';
		|en = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date'; fa = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|it = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|pl = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|tr = 'Fiyatların belirlenmesini belirli bir süre için sınırla: Fiyatlar belirli bir süre için ayarlanır,
		|bu sürenin sonunda önceki fiyatlara geri dönülür'");
	
	Items.PriceValidityDate1.ToolTip = HintTextPeriod;
	Items.PriceValidityDate1.ToolTipRepresentation = ToolTipRepresentation.Button;
	
	EventHintText = NStr("vi = 'Hoạt động marketing mà đơn  giá được thiết lập trong phạm vi đó';
						|ru = 'Маркетинговое мероприятие, в рамках которого устанавливаются цены';
						|en = 'Marketing activity within which prices are set'; fa = 'Marketing activity within which prices are set';
						|it = 'Marketing activity within which prices are set';
						|pl = 'Marketing activity within which prices are set';
						|tr = 'Fiyatların belirlendiği pazarlama faaliyeti'");
	
	Items.MarketingActivity.ToolTip = EventHintText;
	Items.MarketingActivity.ToolTipRepresentation = ToolTipRepresentation.Button;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetQuickEditVisibility(ThisObject);
	
	SetTemporaryPricesWhenChangingOnServer(ThisObject);
	
	ConfigurePriceKeyColumns();
	
	PriceManagementSystemServerCall.SetPropertiesOfSceneryInformingAboutRemovalOfPricingVersion20(Items);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OpenWaitingWindowApplySettingsInBackground();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Not AllowClose And QuestionIsDisplayed <> True And Not Exit Then
		
		QuestionIsDisplayed = True;
		
		CallbackDescription = New CallbackDescription("ProcessingIssueResultBeforeClosing", ThisObject);
		Buttons = New ValueList;
		Buttons.Add("WriteAndClose", NStr("vi = 'Áp dụng';
											|ru = 'Применить';
											|en = 'Apply'; fa = 'اعمال';
											|it = 'Applica';
											|pl = 'Apply';
											|tr = 'Uygula'"));
		Buttons.Add("CloseWithoutSaving", NStr("vi = 'Hủy thay đổi đơn giá';
												|ru = 'Отменить изменения цен';
												|en = 'Undo changes in prices'; fa = 'Undo changes in prices';
												|it = 'Annullare le variazioni di prezzi';
												|pl = 'Anulować zmiany cen';
												|tr = 'Fiyat değişikliklerini iptal et'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		QueryText = NStr("vi = 'Áp dụng đơn giá thay đổi?';
						|ru = 'Применить измененные цены?';
						|en = 'Apply changed prices?'; fa = 'Apply changed prices?';
						|it = 'Applicare i prezzi modificati?';
						|pl = 'Zastosować zmienione ceny?';
						|tr = 'Değiştirilen fiyatları uygula?'");
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
		StandardProcessing = False;
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ImportFromExcel"
		And Parameter.OwnerForm = UUID Then
		SetVisibilityOfEditColumns(ThisObject, True);
		ImportResult1 = LoadFromExcelOnServer(Parameter);
		If Not ImportResult1.Completed2 Then
			ShowMessageBox(,ImportResult1.ErrorDescription);
		EndIf;
		Modified = True;
	EndIf;
	
	If EventName = "ChangingTypeOfPrices" Then
		UpdateSettingsForPriceTypes();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.PriceList.Form.FormSettings" Then
		PriceChangeSessionIsActive = False;
		ClearSavedDocumentsAndApplySettings(ValueSelected);
		OpenWaitingWindowApplySettingsInBackground();
	ElsIf ChoiceSource.FormName = "DataProcessor.PriceList.Form.SearchForm" Then
		
		For Each TreeRow In PriceTree.GetItems() Do
			If TreeRow.Products = ValueSelected Then
				Items.PriceTree.CurrentRow = TreeRow.GetID();
				Return;
			EndIf;
		EndDo;
		
		ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy mặt hàng';
										|ru = 'Номенклатура на найдена';
										|en = 'Items are not found'; fa = 'Items are not found';
										|it = 'L''articolo non è stato trovato';
										|pl = 'Nomenklatura nie została znaleziona';
										|tr = 'Ürün bulunamadı'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Title = TitleText(ThisObject);
	
	If PriceTree.GetItems().Count() = 0 Then
		Return;
	EndIf;
	
	Date = EndOfDay(Date);
	
	If Items.CommandBarPages.CurrentPage = Items.CommandBarPages.ChildItems.ViewPage Then
		ApplySettings();
		OpenWaitingWindowApplySettingsInBackground();		
		Return;
	EndIf;
	
	UpdateOldProductPricesOnServer();
	
	NeedToRecalculate = False;
	
	// To find out if recalculation is necessary, let's check that the selected prices
	// have influencing prices with a currency other than the currency of the selected price.
	
	For Each CurRow In SelectedPrices Do
		
		If CurRow.Selected_5 And
			CurRow.PricingMethod <> PredefinedValue("Enum.PriceSettingMethods.Manually") Then
			
			For Each InfluencingPrice In CurRow.InfluencingPrices Do
				
				FoundRow = Undefined;
				For Each SelectedPrice In SelectedPrices Do
					If SelectedPrice.Ref = InfluencingPrice.Value Then
						FoundRow = SelectedPrice;
					EndIf;
				EndDo;
					
				If FoundRow = Undefined Then
					Continue;
				EndIf;
				
				If CurRow.Currency <> FoundRow.Currency Then
					NeedToRecalculate = True;
					Break;
				EndIf;
				
			EndDo;
			
			If NeedToRecalculate Then
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not NeedToRecalculate Then
		Return;
	EndIf;
	
	UserAnswer = Undefined;
	ShowQueryBox(New CallbackDescription("DateOnChangeCompletion", ThisObject), 
		NStr("vi = 'Trong chứng từ đã chọn dạng giá có tiền tệ khác với dạng giá ảnh hưởng. Tính lại đơn giá?';
			|ru = 'В документе выбраны виды цены с валютой, отличной от влияющих видов цен. Пересчитать цены?';
			|en = 'Price types with the currency different from the influencing price types are selected in the document. Recalculate the prices?'; fa = 'Price types with the currency different from the influencing price types are selected in the document. Recalculate the prices?';
			|it = 'Nel documento sono stati selezionati i tipi di prezzi con valuta diversa dai tipi di prezzi influenzanti. Ricalcolare i prezzi?';
			|pl = 'W dokumencie wybrano rodzaje cen z walutą, inną niż wpływających rodzajów cen. Przeliczyć ponownie?';
			|tr = 'Belgede, etkileyen fiyat türleri dışında bir para birimine sahip fiyat türleri seçildi. Fiyatlar hesaplansın mı?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OptionToChangeThePriceOnChange(Item)
	SetQuickEditVisibility(ThisObject);
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ReformatPriceTable(True);

EndProcedure

&AtClient
Procedure HyperlinkFilterIsSetClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenPriceListSettingsForm(Not UseSeveralPriceTypes);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceTree

&AtClient
Procedure PriceTreeOnActivateCell(Item)

	UpdateInformationLine();
	
EndProcedure

&AtClient
Procedure PriceTreeOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateInformationLine();
	
EndProcedure

&AtClient
Procedure PriceTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PriceTree" + "Products" Or Field.Name = "PriceTree" + "ProductKind" Then
		If ValueIsFilled(Items.PriceTree.CurrentData.Characteristic)
					Or ValueIsFilled(Items.PriceTree.CurrentData.PricingVariant)
					Or ValueIsFilled(Items.PriceTree.CurrentData.PricingBatch)
					Or ValueIsFilled(Items.PriceTree.CurrentData.PricingPackage) Then
			Return
		EndIf;
		
		StandardProcessing = False;
		If ValueIsFilled(Items.PriceTree.CurrentData.Products) Then
			ShowValue(Undefined, Items.PriceTree.CurrentData.Products);
		ElsIf ValueIsFilled(Items.PriceTree.CurrentData.ProductKind) Then 	
			ShowValue(Undefined, Items.PriceTree.CurrentData.ProductKind);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreeOnStartEdit(Item, NewRow, Copy)
	
	Changed_Price = False;
	
EndProcedure

&AtServer
Procedure PriceTreePackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName);
EndProcedure

&AtServer
Procedure PriceTreeCurrencyWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName, "Currency");
EndProcedure

&AtServerNoContext
Function GetPriceHistoryData(ParametersStructure)
	
	If ParametersStructure.UsePriceManagementSystem25 Then
		Query = New Query();
		Query.Text = "SELECT TOP 6
		|	ItemsPrices25.Period AS Period,
		|	ItemsPrices25.Price AS Price,
		|	ItemsPrices25.Currency AS Currency,
		|	ItemsPrices25.MarketingActivity AS MarketingActivity
		|FROM
		|	InformationRegister.ItemsPrices25 AS ItemsPrices25
		|WHERE
		|	ItemsPrices25.Products = &Products
		|	AND ItemsPrices25.PricingVariant = &PricingVariant
		|	AND ItemsPrices25.PricingBatch = &PricingBatch
		|	AND ItemsPrices25.PricingPackage = &PricingPackage
		|	AND ItemsPrices25.PriceKind = &PriceKind
		|ORDER BY
		|	ItemsPrices25.Period DESC";
		
		Query.Parameters.Insert("Products", ParametersStructure.Products);
		Query.Parameters.Insert("PricingVariant", ParametersStructure.PricingVariant);
		Query.Parameters.Insert("PricingPackage", ParametersStructure.PricingPackage);
		Query.Parameters.Insert("PricingBatch", ParametersStructure.PricingBatch);
		Query.Parameters.Insert("PriceKind", ParametersStructure.PriceKind);
	Else
		Query = New Query();
		Query.Text = "SELECT TOP 6
		|	ItemsPrices.Period AS Period,
		|	ItemsPrices.Price AS Price,
		|	ItemsPrices.Currency AS Currency,
		|	ItemsPrices.MarketingActivity AS MarketingActivity
		|FROM
		|	InformationRegister.ItemsPrices AS ItemsPrices
		|WHERE
		|ItemsPrices.Products = &Products AND 
		|ItemsPrices.Characteristic = &Characteristic AND
		|ItemsPrices.PriceKind = &PriceKind 
		|ORDER BY ItemsPrices.Period DESC";
		
		Query.Parameters.Insert("Products", ParametersStructure.Products);
		Query.Parameters.Insert("Characteristic", ParametersStructure.Characteristic);
		Query.Parameters.Insert("PriceKind", ParametersStructure.PriceKind);
	EndIf;
	PriceHistory = Query.Execute().Unload();
		
	Return PriceHistory;
	
EndFunction

&AtServerNoContext
Function GetPriceOnDate(CurPriceDate, PriceKind, FillParameters)
	Filter = Undefined;
	
	If FillParameters.UsePriceManagementSystem25 Then
		Query = New Query();
		Query.Parameters.Insert("Period",CurPriceDate);
		Query.Parameters.Insert("PriceKind", PriceKind);
		Query.Parameters.Insert("Products", FillParameters.Products);
		Query.Parameters.Insert("PricingVariant", FillParameters.PricingVariant);
		Query.Parameters.Insert("PricingBatch", FillParameters.PricingBatch);
		Query.Parameters.Insert("PricingPackage", FillParameters.PricingPackage);
		
		Query.Text = "SELECT
		|	ItemPrices25CrossSectionOfTheLatest.Period AS Period,
		|	ItemPrices25CrossSectionOfTheLatest.Price AS Price,
		|	ItemPrices25CrossSectionOfTheLatest.Currency AS Currency,
		|	ItemPrices25CrossSectionOfTheLatest.MarketingActivity AS MarketingActivity
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(&Period,
		|	PriceKind = &PriceKind
		|	AND Products = &Products
		|	AND PricingVariant = &PricingVariant
		|	AND PricingBatch = &PricingBatch
		|	AND PricingPackage = &PricingPackage) AS ItemPrices25CrossSectionOfTheLatest" ;
	Else	
		Query = New Query();
		Query.Parameters.Insert("Period",CurPriceDate);
		Query.Parameters.Insert("PriceKind", PriceKind);
		Query.Parameters.Insert("Products", FillParameters.Products);
		Query.Parameters.Insert("Characteristic", FillParameters.Characteristic);
		
		Query.Text = "SELECT
		|	ItemPricesCrossSectionOfTheLatest.Period AS Period,
		|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
		|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency,
		|	ItemPricesCrossSectionOfTheLatest.MarketingActivity AS MarketingActivity
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(&Period,
		|	PriceKind = &PriceKind
		|	AND Products = &Products
		|	AND Characteristic = &Characteristic) AS ItemPricesCrossSectionOfTheLatest
		|	" ;
	EndIf;
	Result = Query.Execute().Unload();
	If Result.Count() > 0 Then
		Filter = New Structure;
		Filter.Insert("Period",                   Result[0].Period);
		Filter.Insert("Price",                     Result[0].Price);
		Filter.Insert("Currency",                   Result[0].Currency);
		Filter.Insert("MarketingActivity", Result[0].MarketingActivity);		
	EndIf;
	
	Return Filter;
EndFunction

&AtServerNoContext
Function ThereIsPriceSetByFutureDate(PriceKind, Products, Characteristic)
	
	Result = False;
	
	Query = New Query();
	Query.Parameters.Insert("PriceKind", PriceKind);
	Query.Parameters.Insert("Products", Products);
	Query.Parameters.Insert("Characteristic", Characteristic);
	Query.Text = "SELECT
	                |	ItemPricesCrossSectionOfTheLatest.Period AS Period
	                |FROM
	                |	InformationRegister.ItemsPrices.SliceLast(,
					|	PriceKind = &PriceKind
					|	AND Products = &Products
					|	AND Characteristic = &Characteristic) AS ItemPricesCrossSectionOfTheLatest
					|	";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = (Selection.Period > CurrentDate());	
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext	
Function GetHistoryInformationLine(Parameters)
	
	DatePriceLine = NStr("vi = 'Đơn giá ngày %1';
						|ru = 'Цена на %1';
						|en = 'Price as of %1'; fa = 'Price as of %1';
						|it = 'Prezzo di %1';
						|pl = 'Cena na %1';
						|tr = '%1 fiyatı'") + " ";
	DatePriceLine = StringFunctionsClientServer.SubstituteParametersToString(DatePriceLine, Format(Parameters.Period,"DLF=D;"));
	PriceValueString =  StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ' %2 %3';
																						|ru = ' %2 %3';
																						|en = ' %2 %3'; fa = ' %2 %3';
																						|it = ' %2 %3';
																						|pl = ' %2 %3';
																						|tr = ' %2 %3'"),,Format(Parameters.Price,"NFD=2"), Parameters.Currency); 
	FormattedStringTrendIcon = New FormattedString(" ");
	FormattedStringIndent = New FormattedString(" ");
	If Parameters.PriceChanged_ Then
		If Parameters.IsWebClient Then
			FormattedStringStartOfString = New FormattedString(New FormattedString("", " V ",""),New Font(,,True),,);
		Else	
			FormattedStringStartOfString = New FormattedString("",PictureLib.Change, "");
		EndIf;
	ElsIf Parameters.Period > CurrentDate() Then
		If Parameters.IsWebClient Then
			FormattedStringStartOfString = New FormattedString(New FormattedString("", " ! ",""),,WebColors.Red);
		Else	
			FormattedStringStartOfString = New FormattedString("", PictureLib.Attention16, "");
		EndIf;
	Else
		FormattedStringStartOfString = New FormattedString("    ");
	EndIf;
	
	PriceValueString = New FormattedString(PriceValueString,New Font(,,True));
	
	FormattedStringPriceAsOfDate = New FormattedString(DatePriceLine,FormattedStringIndent,PriceValueString); 
	
	If Parameters.Property("PreviousPrice") 
		And Parameters.PreviousPrice <> 0  
		And Parameters.PreviousPrice <> Parameters.Price Then
			PriceChange_ = Parameters.Price - Parameters.PreviousPrice;
			ChangePercentage = Parameters.Price/(Parameters.PreviousPrice/100)-100; 
			PriceChangeLine = New FormattedString("",Format(PriceChange_,"NFD=2"));
			PreviousCurrency = Parameters.PreviousCurrency;//CatalogRef.Currencies
			PriceChangeCurrencyString = New FormattedString(" ", PreviousCurrency["Description"], " ");
			PercentageChangeString = New FormattedString(" (",Format(ChangePercentage,"NFD=2"),"%) ");	
		If PriceChange_ > 0 Then
			#If Not WebClient Then
				FormattedStringTrendIcon = New FormattedString("", PictureLib.TrendIconGrowthInARange,"");
			#EndIf				
		ElsIf  PriceChange_ < 0 Then 
			#If Not WebClient Then
				FormattedStringTrendIcon = New FormattedString("", PictureLib.TrendIconDeclineIsImproving,"");
			#EndIf	
		Else
			 FormattedStringTrendIcon = New FormattedString("");
		EndIf;
		
		FormattedStringUpdate = New FormattedString(PriceChangeLine,PriceChangeCurrencyString, PercentageChangeString);
	Else 
		FormattedStringUpdate = New FormattedString("  ");
	EndIf;		
	
	If Parameters.Property("MarketingActivity") And ValueIsFilled(Parameters.MarketingActivity) Then
		FormattedStringMarketingEvent = New FormattedString("on stocks",New Font(,,True),WebColors.Coral,,GetURL(Parameters.MarketingActivity));
	Else
		FormattedStringMarketingEvent = " ";
	EndIf;		
	
	FormattedHistoryString = New FormattedString(
						FormattedStringIndent,
						FormattedStringPriceAsOfDate);
						
	FormattedSpeakerString = New FormattedString(
						FormattedStringUpdate);
												
	FormattedSpeakerString = New FormattedString(FormattedSpeakerString,New Font(,,True),,);
	FormattedHistoryString = New FormattedString(FormattedHistoryString,New Font(,,True),,);

	
	If Not Parameters.ThisIsCurPrice Then 
		FormattedHistoryString = New FormattedString(FormattedHistoryString,New Font(,,True),WebColors.Gray);
		FormattedSpeakerString = New FormattedString(FormattedSpeakerString,New Font(,,True),WebColors.Gray);	
	EndIf;					
						
	HistoryStringStructure = New Structure();
	HistoryStringStructure.Insert("FormattedHistoryString",FormattedHistoryString);
	HistoryStringStructure.Insert("FormattedSpeakerString",FormattedSpeakerString);
	HistoryStringStructure.Insert("FormattedStringTrendIcon",FormattedStringTrendIcon);
	HistoryStringStructure.Insert("FormattedStringStartOfString",FormattedStringStartOfString);
	HistoryStringStructure.Insert("FormattedStringByStock",FormattedStringMarketingEvent);
	
	Return HistoryStringStructure;
						
EndFunction

&AtServer
Function GenerateStringOfCurrenciesFromArray(ArrayOfCurrencies)
	
	CurrencyString = "";
	For Indus=0 To ArrayOfCurrencies.Count()-1 Do
		Currency = ArrayOfCurrencies.Get(Indus);//CatalogRef.Currencies
		CurrencyString = CurrencyString + Currency.Description;
		If Indus<>ArrayOfCurrencies.Count()-1 Then
			CurrencyString = CurrencyString + NStr("vi = ',';
													|ru = ',';
													|en = ','; fa = ',';
													|it = ',';
													|pl = ',';
													|tr = ','")+ " ";
		EndIf;
	EndDo;
	
	Return CurrencyString;
EndFunction

&AtClient
Function GetInformationStringForPriceType(Var_Items, PriceKind, ArrayOfCurrencies, CurColumnName) Export
		
	FormattedStringPriceView = "";
	FormattedStringWarningMultipleCurrencies = "";
	CurrentData = Var_Items.PriceTree.CurrentData;
	GroupOfPrices = Var_Items.Find("PriceTree" + "GroupPrices" + CurColumnName);
	
	If GroupOfPrices <> Undefined Then
		If CurrentData.Property("Currency" + CurColumnName) Then
			NameOfCurrency = New FormattedString( " " + String(CurrentData["Currency" + CurColumnName]),New Font(,,True));
		Else	
			NameOfCurrency = New FormattedString(Right(GroupOfPrices.Title, 4),New Font(,,True));
		EndIf;
		NameOfPriceType = Left(GroupOfPrices.Title, StrLen(GroupOfPrices.Title) - 5);
	EndIf;
	
	FormattedStringPriceView = New FormattedString(NameOfPriceType, New Font(,,True),,,GetURL(PriceKind));
	
	#If WebClient Then
		FormattedStringPriceView = New FormattedString("  ", FormattedStringPriceView);
	#Else
		FormattedStringPriceView = New FormattedString("  ", GroupOfPrices.HeaderPicture, " ", FormattedStringPriceView);
	#EndIf
	
	If ArrayOfCurrencies.Count()>1 Then
		
		CurrencyString = GenerateStringOfCurrenciesFromArray(ArrayOfCurrencies);
		FormattedCurrencyString = New FormattedString(CurrencyString, New Font(,,True),WebColors.Red,,"LinkDifferentCurrencies");
		
		#If WebClient Then
			FormattedStringWarningMultipleCurrencies = New FormattedString("   ", CurrencyString);
		#Else
			FormattedStringWarningMultipleCurrencies = New FormattedString("   ",PictureLib.Attention16, " ", FormattedCurrencyString);
		#EndIf	
		
	EndIf;
	
	FormattedInformationStringByPriceType = New FormattedString(FormattedStringPriceView, FormattedStringWarningMultipleCurrencies);
	
	Return FormattedInformationStringByPriceType;
	
EndFunction

&AtClient
Procedure ClearHistoryInformation()
	
	IsBlankString = New FormattedString("");
	Items.SceneryHistory.Title 		= IsBlankString;
	Items.SpeakerDecoration.Title 		= IsBlankString;
	Items.DecorationTrend.Title 			= IsBlankString;
	Items.DecorationBeginningOfTheLine.Title 	= IsBlankString;
	Items.DecorationsForThePromotion.Title 		= IsBlankString;
	
EndProcedure
	
&AtClient
Procedure FillInPriceChangeHistoryGroup(FillParameters)
	
	CurrentData = FillParameters.CurrentData;
	ColumnName = FillParameters.ColumnName;
	PriceChanged_ = CurrentData["ChangedManually" + ColumnName];
	OldPrice = CurrentData["OldPrice" + ColumnName];
	NewPrice = CurrentData[ColumnName];
	Currency = CurrentData["Currency" + ColumnName];
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Products", FillParameters.Products);
	ParametersStructure.Insert("Characteristic", FillParameters.Characteristic);
	ParametersStructure.Insert("PricingVariant", FillParameters.PricingVariant);
	ParametersStructure.Insert("PricingBatch", FillParameters.PricingBatch);
	If FillParameters.PricingPackage = FillParameters.UnitOfMeasure Then
		ParametersStructure.Insert("PricingPackage", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	Else
		ParametersStructure.Insert("PricingPackage", FillParameters.PricingPackage);
	EndIf;
	ParametersStructure.Insert("PriceKind", FillParameters.PriceKind);
	ParametersStructure.Insert("PriceChanged_", PriceChanged_);
	ParametersStructure.Insert("OldPrice", OldPrice);
	ParametersStructure.Insert("NewPrice", NewPrice);
	ParametersStructure.Insert("Currency", Currency);
	ParametersStructure.Insert("Filter", FillParameters.Filter);
	ParametersStructure.Insert("Date", Date);
	ParametersStructure.Insert("UsePriceManagementSystem25", FillParameters.UsePriceManagementSystem25);
	
	#If WebClient Then
		ParametersStructure.Insert("IsWebClient", True);
	#Else	
		ParametersStructure.Insert("IsWebClient", False);
	#EndIf
	
	StructureOfArraysOfStrings = GetInformationHistoryLines(ParametersStructure);
	If Not StructureOfArraysOfStrings.EmptyHistory Then

		Items.SceneryHistory.Title = New FormattedString(StructureOfArraysOfStrings.ArrayOfFormattedStrings);
		Items.SpeakerDecoration.Title = New FormattedString(StructureOfArraysOfStrings.ArrayOfFormattedDynamicsStrings);
		Items.DecorationTrend.Title = New FormattedString(StructureOfArraysOfStrings.ArrayOfFormattedRowsOfTrendIcons);
		Items.DecorationBeginningOfTheLine.Title = New FormattedString(StructureOfArraysOfStrings.ArrayOfFormattedStringsAtBeginningOfLine); 
		Items.DecorationsForThePromotion.Title = New FormattedString(StructureOfArraysOfStrings.ArrayOfFormattedStringsByStock); 
		
		Items.InformationTableGroup.Visible 		= True; 
		Items.PriceHistoryReportGroup.Visible 		= True; 
		Items.GroupLabelEmptyHistory.Visible 	= False; 
	Else
		Items.InformationTableGroup.Visible 		= False; 
		Items.PriceHistoryReportGroup.Visible 		= False; 
		Items.GroupLabelEmptyHistory.Visible 	= True; 
	EndIf;
	
EndProcedure 

&AtClient
Function GetCurPriceDate()
	
	If ValueIsFilled(ValidPriceDate) Then
		PriceCurDate = ValidPriceDate;
	ElsIf ValueIsFilled(Date) Then
		PriceCurDate = BegOfDay(Date)-1;
	Else
		PriceCurDate = BegOfDay(CurrentDate())-1;
	EndIf;
	
	Return PriceCurDate;
	
EndFunction
 
&AtServer
Function FillTableByTraversingTree(Tree)
	
	TableOfCurrenciesByTypeOfPrices = New ValueTable();
	TableOfCurrenciesByTypeOfPrices.Columns.Add("PriceKind");
	TableOfCurrenciesByTypeOfPrices.Columns.Add("Currency");
	
	For Each Column In Tree.Columns Do	
		
		If StrFind(Column.Name, "PriceKind")>0 Then
			
			SubstringPosition  = StrFind(Column.Name, "PriceKind");
			If SubstringPosition <> 0 Then
				ColumnName = Right(Column.Name, StrLen(Column.Name) - SubstringPosition + 1);
			EndIf;
			
			If ColumnName = Column.Name Then
				
				FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
				If FoundTypesOfPrices.Count() > 0 Then
					PriceKind = FoundTypesOfPrices[0].Ref;
					CurrencyColumnName = "Currency" + ColumnName;
					
					ArrayOfCurrencies = New Array();
					FillArrayByTraversingTree(Tree, CurrencyColumnName, ArrayOfCurrencies);
					
					For Indus=1 To ArrayOfCurrencies.Count() Do
						CurrencyTableRow = TableOfCurrenciesByTypeOfPrices.Add();
						CurrencyTableRow.PriceKind = PriceKind;
						CurrencyTableRow.Currency = ArrayOfCurrencies[Indus-1];
					EndDo;
					
				EndIf;
				
			EndIf;
		EndIf;
		
	EndDo;

	Return TableOfCurrenciesByTypeOfPrices;
	
EndFunction

&AtServer
Function GetArrayOfRowsFromValueTable(ValueTable)
	
	RowsArray = New Array;
	
	For Each Page1 In ValueTable Do
		RowsArray.Add(New Structure("PriceKind, Currency",Page1.PriceKind,Page1.Currency));
	EndDo;
	
	Return RowsArray;
	
EndFunction

&AtServer
Function FillInArrayOfCurrenciesByPriceType()
	
	Tree = FormAttributeToValue("PriceTree");
	TableOfCurrenciesByTypeOfPrices = New ValueTable;
	TableOfCurrenciesByTypeOfPrices.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfCurrenciesByTypeOfPrices.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	TableOfCurrenciesByTypeOfPrices = FillTableByTraversingTree(Tree);
	ArrayOfCurrenciesByPriceType = GetArrayOfRowsFromValueTable(TableOfCurrenciesByTypeOfPrices);
	
	Return ArrayOfCurrenciesByPriceType;
EndFunction

&AtServer
Procedure FillArrayByTraversingTree(Tree, CurrencyColumnName, ArrayOfCurrencies)
	
	For Each Page1 In Tree.Rows Do
		If Page1.Rows.Count() > 0 Then
			FillArrayByTraversingTree(Page1, CurrencyColumnName, ArrayOfCurrencies);
		Else
			LineCurrency = Page1[CurrencyColumnName];
			If ValueIsFilled(LineCurrency) And ArrayOfCurrencies.Find(LineCurrency) = Undefined Then
				
				ArrayOfCurrencies.Add(LineCurrency);
				
			EndIf;
		EndIf;
	EndDo;
		
EndProcedure

&AtServer
Function GetArrayOfUsedCurrencies(CurrencyColumnName, SelectedLinesOnly = False)

	ArrayOfCurrencies = New Array;
	
	If SelectedLinesOnly Then
		For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
			
			TSRow = PriceTree.FindByID(IDOfPriceTreeRow);
			LineCurrency = TSRow[CurrencyColumnName];
			
			
			If ValueIsFilled(LineCurrency) And ArrayOfCurrencies.Find(LineCurrency) = Undefined Then
			
				ArrayOfCurrencies.Add(TSRow[CurrencyColumnName]);
				
			EndIf;
			
		EndDo;
	Else
		
		Tree = FormAttributeToValue("PriceTree");
		FillArrayByTraversingTree(Tree, CurrencyColumnName, ArrayOfCurrencies);
		
	EndIf;
	
	Return ArrayOfCurrencies;
	
EndFunction

// Procedure-handler of the event" when Changing "of the" wood Packaging " field.
// 
// Parameters:
// 	Item - FormField
&AtClient
Procedure PriceTreePackagingWhenChangingClient(Item)
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "Package", "NoEditingAllowed");

	CurrentRow = PriceTree.FindByID(CurrentData.GetID());

	CurrentValue   = CurrentData[CurColumnName];
	
	CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangePackingInPriceTreeRow");
	CallParameters.CurrentValue 								= CurrentValue;
	CallParameters.CurColumnName								= CurColumnName;
	CallParameters.NameOfEditBanColumn					= NameOfEditBanColumn;
	
	SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
	
	UpdateInformationLine();
	
	PriceTreePackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
EndProcedure

// The price tree is the currency when the client changes.
// 
// Parameters:
//  Item - FormItems
&AtClient
Procedure PriceTreeCurrencyWhenChangedClient(Item)

	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "Currency", "NoEditingAllowed");

	CurrentRow = PriceTree.FindByID(CurrentData.GetID());

	CurrentValue   = CurrentData[CurColumnName];
	
	CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangeCurrencyInPriceTreeLine");
	CallParameters.CurrentValue 								= CurrentValue;
	CallParameters.CurColumnName								= CurColumnName;
	CallParameters.NameOfEditBanColumn					= NameOfEditBanColumn;
	
	SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
	
	UpdateInformationLine();
	
	PriceTreeCurrencyWhenChangedOnServer(CurrentData.GetID(), CurColumnName);

EndProcedure

// Procedure-handler for the event" when Changing "the" wood Price " field.
//
&AtClient
Procedure PriceTreePriceWhenCustomerChanges(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	ColumnNamePackaging = StrReplace(Item.Name, "PriceTree" + "PriceKind", "Package" + "PriceKind");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "PriceKind", "NoEditingAllowed" + "PriceKind");
	
	ChangedPercentage = False;
	AmountChanged_ = False;
	ChangedFormula = False;
	ChangePercentage = 0;
	AmountOfChange = 0;
	NewFormula = "";
	
	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	
	If StrFind(CurColumnName, "ChangePercentage" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "ChangePercentage" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = Round(
			CurrentData["OldPrice" + CurColumnName] * ((CurrentData["ChangePercentage"+CurColumnName] / 100) + 1),
			15,
			2);
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];
		ChangedPercentage = True;
		ChangePercentage = CurrentData["ChangePercentage"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"NoEditingAllowed" + "PriceKind");
	EndIf;
	If StrFind(CurColumnName, "AmountOfChange" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "AmountOfChange" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = CurrentData["OldPrice" + CurColumnName] + CurrentData["AmountOfChange" + CurColumnName];
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		AmountChanged_ = True;
		AmountOfChange = CurrentData["AmountOfChange"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"NoEditingAllowed" + "PriceKind");
	EndIf;
	If StrFind(CurColumnName, "Formula" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "Formula" + "PriceKind", "PriceKind");
		
		CurrentData["AmountOfChange"+CurColumnName] = CurrentData[CurColumnName] - CurrentData["OldPrice" + CurColumnName];		
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		ChangedFormula = True;
		NewFormula = CurrentData["Formula"+CurColumnName];
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "Formula" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"Package" + "PriceKind");
		NameOfEditBanColumn = StrReplace(StrReplace(Item.Name, "Formula" + "PriceKind", "PriceKind"), 
							"PriceTree" + "PriceKind", 
							"NoEditingAllowed" + "PriceKind");
	EndIf;
	
	If CurrentData[NameOfEditBanColumn] Then
		Return;
	EndIf;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	CurrentData["AmountOfChange" + CurColumnName] = CurrentData[CurColumnName] 
														- CurrentData["OldPrice" + CurColumnName];
	CurrentData["ChangedManually"       + CurColumnName] = 
							(CurrentData["AmountOfChange" + CurColumnName] <> 0);
	CurrentData["ChangedAutomatically" + CurColumnName] = False;
	
	If CurrentData["OldPrice"+CurColumnName] <> 0 Then
		CurrentData["ChangePercentage"+CurColumnName] = Round(
			100 * (CurrentData[CurColumnName] - CurrentData["OldPrice"+CurColumnName]) 
			/ CurrentData["OldPrice" + CurColumnName], 5, 2);
	Else
		CurrentData["ChangePercentage"+CurColumnName] = 0;
	EndIf;
	
	If FillInCharacteristicPricesByProductsAutomatically Then
		Products = CurrentData.Products;
		
		ArrayOfProductPackagingStructures = New Array;
		ComplianceOfFactorsOfPackagesOfProductRange = Undefined;
		
		SourcePricePackingRatio = 1;
		
		If UseItemPackages Then
			
			CurPackingValue = CurrentData[ColumnNamePackaging];
			If ValueIsFilled(CurPackingValue) Then
				Structure = SettingPricesClientServer.InitializeProductPackagingDescription();
				Structure.Products = Products;
				Structure.Package = CurPackingValue;
				ArrayOfProductPackagingStructures.Add(Structure);
			EndIf;
			
			CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("FillOutProductPackaging");
			CallParameters.ColumnNamePackaging 					= ColumnNamePackaging;
			CallParameters.NameOfEditBanColumn 	= NameOfEditBanColumn;
			CallParameters.ArrayOfProductPackagingStructures 	= ArrayOfProductPackagingStructures;
			
			SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
			
			If ArrayOfProductPackagingStructures.Count() > 0 Then
				ComplianceOfFactorsOfPackagesOfProductRange = CoefficientsOfProductPackages(ArrayOfProductPackagingStructures);
			EndIf;
			
			// Let's determine the packing coefficient of the current price
		 
			If ValueIsFilled(CurPackingValue) And ComplianceOfFactorsOfPackagesOfProductRange <> Undefined Then
				SearchResult = SettingPricesClientServer.GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																									Products, 
																									CurPackingValue);
				If SearchResult <> Undefined Then
					SourcePricePackingRatio = SearchResult;
				EndIf;
			EndIf;
		EndIf;
		
		CurrentValue = CurrentData[CurColumnName];
		
		CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangeDataInPriceTreeRow");
		CallParameters.ColumnNamePackaging 								= ColumnNamePackaging;
		CallParameters.NameOfEditBanColumn 				= NameOfEditBanColumn;
		CallParameters.ComplianceOfFactorsOfPackagesOfProductRange	= ComplianceOfFactorsOfPackagesOfProductRange;
		CallParameters.CurPackingValue							= CurPackingValue;
		CallParameters.CurrentValue 								= CurrentValue;
		CallParameters.SourcePricePackingRatio				= SourcePricePackingRatio;
		CallParameters.CurColumnName								= CurColumnName;
		CallParameters.NewFormula									= NewFormula;
		CallParameters.ChangePercentage								= ChangePercentage;
		CallParameters.AmountOfChange									= AmountOfChange;
		CallParameters.ChangedPercentage									= ChangedPercentage;
		CallParameters.AmountChanged_									= AmountChanged_;
		CallParameters.ChangedFormula									= ChangedFormula;
		CallParameters.Products									= Products;
		CallParameters.UseItemPackages				= UseItemPackages;
		
		SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
		
	EndIf;
	
	CalculatePricesByRowIDOnServer(CurrentData.GetID(),CurColumnName);
	
EndProcedure

// The price tree VAT rate on changes by the client.
// 
// Parameters:
//  Item - FormItems
&AtClient
Procedure PriceTreeVATRateONChangeCustomer(Item)

	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");
	NameOfEditBanColumn = StrReplace(Item.Name, "PriceTree" + "VATRate", "NoEditingAllowed");

	CurrentData["ChangedManually" + CurColumnName] = 
			CurrentData[CurColumnName] <> CurrentData["Original" + CurColumnName];
	CurrentData["ChangedAutomatically" + CurColumnName] = False;
	
	CurrentValue   = CurrentData[CurColumnName];
	CallParameters = SettingPricesClient.ChangeParametersInPriceTreeElement("ChangePersonalIncomeTaxRateInLineOfPriceTree");
	CallParameters.CurrentValue 					= CurrentValue;
	CallParameters.CurColumnName					= CurColumnName;
	CallParameters.NameOfEditBanColumn		= NameOfEditBanColumn;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	SettingPricesClient.ApplyChangesToPriceTree(CurrentRow, CallParameters);
	UpdateInformationLine();
	
EndProcedure

#EndRegion

#Region FormTableElementEventHandlersAreBoundDynamically

&AtClient
Procedure Attachable_PriceTreePriceWhenChanged(Item)
	
	Changed_Price = True;
	
	PriceTreePriceWhenCustomerChanges(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreeFormulaWhenChanging(Item)
	
	ClearMessages();
	
	ColumnNameFormula = StrReplace(Item.Name, "PriceTree", "");
	
	FormulaText = Items.PriceTree.CurrentData[ColumnNameFormula];
	Operands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(FormulaText);
	ResultType = New TypeDescription("Number");
	FormulaValidationParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
	
	If ProcessingOfFormulasClient.CheckFormula(FormulaText,
		Operands,
		ResultType,
		FormulaValidationParameters) Then
			
		Changed_Price = True;
		
		PriceTreePriceWhenCustomerChanges(Item);
		
		//  current column + dependent
		ArrayOfPriceTypes = New Array();
		PriceKind = GetPriceViewByColumnName(Item.Name);
		If PriceKind <> Undefined Then
			
			ArrayOfPriceTypes.Add(PriceKind.Ref);
			
			CalculationParameters = New Structure();
			CalculationParameters.Insert("ImportOldPrices", False);
			CalculationParameters.Insert("RoundingUpManualPrices", False);
			CalculationParameters.Insert("TypesOfPrices", ArrayOfPriceTypes);
			CalculationParameters.Insert("SelectedLinesOnly", True);
			CalculationParameters.Insert("OnlyEmpty", False);
			CalculationParameters.Insert("CalculationByFormulas", True);
			
			CalculatePricesOnServer(CalculationParameters);
			
		EndIf;
	
		If Not UseTheEditMode Then
			SetVisibilityOfEditColumns(ThisObject, True);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField
// 	ChoiceData - Arbitrary
// 	StandardProcessing - Boolean
&AtClient
Procedure Attachable_PriceTreeFormulaBeginningOfChoice(Item, ChoiceData, StandardProcessing)

	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	AdditionalParameters = New Structure("NameOfReturnElement", CurColumnName);
	
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersOfPriceEditingForm(Item.Name), Item,,,, 
		New CallbackDescription("FormulasConstructorCompletion", ThisObject,AdditionalParameters), 
		FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

&AtClient
Procedure FormulasConstructorCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If Result <> Undefined Then
		ChangeValueString = Result;
		CurrentData[AdditionalParameters.NameOfReturnElement]	= Result;
		Attachable_PriceTreeFormulaWhenChanging(Items["PriceTree" + AdditionalParameters.NameOfReturnElement]);
	EndIf;

EndProcedure

&AtClient
Procedure FormulasConstructorCompletion_1(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangeValueString = Result;
		
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_PriceTreePackagingWhenChanging(Item)
	
	PriceTreePackagingWhenChangingClient(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PriceTreeCurrencyWhenChanged(Item)

	PriceTreeCurrencyWhenChangedClient(Item);

EndProcedure

&AtClient
Procedure Attachable_PriceTreeVATRateONChange(Item)

	PriceTreeVATRateONChangeCustomer(Item);
	
	If Not UseTheEditMode Then
		SetVisibilityOfEditColumns(ThisObject, True);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Function FillInArrayForRecalculation(FillParameters, PriceKind)
	
	ArrayOfPriceTypes = New Array();
	If OptionToChangeThePrice = 1 Then //change to a percentage
		ArrayOfPriceTypes.Add(New Structure("PriceKind, ChangePercentage", PriceKind.Ref, ChangeValueNumber));
	ElsIf OptionToChangeThePrice = 2 Then // change to value
		ArrayOfPriceTypes.Add(New Structure("PriceKind, AmountOfChange", PriceKind.Ref, ChangeValueNumber));
	ElsIf  OptionToChangeThePrice = 3 Then // change the value
		ArrayOfPriceTypes.Add(New Structure("PriceKind, Price", PriceKind.Ref, ChangeValueNumber));
	ElsIf  OptionToChangeThePrice = 4 Then //change by formula
		ArrayOfPriceTypes.Add(New Structure("PriceKind, Formula", PriceKind.Ref, ChangeValueString));
	EndIf;
	
	OnlySelectedItems = Items.PriceTree.SelectedRows.Count() > 1;
	
	Result = New Structure();
	Result.Insert("ChangeInRelationToOldPrice", FillParameters.ImportOldPrices);
	Result.Insert("ImportOldPrices", 			 FillParameters.ImportOldPrices);
	Result.Insert("TypesOfPrices",                        ArrayOfPriceTypes);
	Result.Insert("SelectedLinesOnly",         OnlySelectedItems);
	Result.Insert("OnlyEmpty",       	 False);
	Result.Insert("RoundingUpManualPrices",            FillParameters.RoundingUpManualPrices);           
	Result.Insert("ApplyRounding",            FillParameters.RoundingUpManualPrices);
	Result.Insert("CalculationByFormulas",               FillParameters.CalculationByFormulas);
	Result.Insert("OptionToChangeThePrice",           OptionToChangeThePrice);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ChangePricesByPercentageOnClientByCallType(CallingFromQuickAccessToolbar, PriceKind = Undefined)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",True);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",False);
	FillParameters.Insert("ConsiderCurrencyDifferences", False);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	If CallingFromQuickAccessToolbar Then
		CalculationParameters = FillInArrayForRecalculation(FillParameters, PriceKind);
		ChangePricesByPercentageOnTheClientCompletion(CalculationParameters);
	Else
		OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
		OpenForm(
			"Document.PriceSetup.Form.SelectionFormOfPercentageChange",
			OpeningParameters,
			ThisObject,,,, New CallbackDescription("ChangePricesByPercentageOnTheClientCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
		
EndProcedure

&AtClient
Procedure ChangePricesByPercentageOnTheClient(Command)
	
	ChangePricesByPercentageOnClientByCallType(False);
	
EndProcedure

&AtClient
Procedure ChangePrices(Command)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",True);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",False);
	FillParameters.Insert("ConsiderCurrencyDifferences", False);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
	
	CalculationParameters = Undefined;
	
	OpenForm(
		"Document.PriceSetup.Form.FormOfPriceChange",
		OpeningParameters,
		ThisObject,,,, New CallbackDescription("ChangePricesOnClientEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangePricesOnClientByCallType(CallingFromQuickAccessToolbar, PriceKind = Undefined)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices", False);
	FillParameters.Insert("RoundingUpManualPrices", True);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas", False);
	FillParameters.Insert("ConsiderCurrencyDifferences",True);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	If CallingFromQuickAccessToolbar Then
		CalculationParameters = FillInArrayForRecalculation(FillParameters, PriceKind);
		ChangePricesNewOptionOnClientEnds(CalculationParameters);
	Else
		ArrayOfCurrenciesByPriceType = FillInArrayOfCurrenciesByPriceType();
		If ArrayOfCurrenciesByPriceType.Count()>0 Then
			FillParameters.Insert("ArrayOfCurrenciesByPriceType",ArrayOfCurrenciesByPriceType);
		EndIf;
		
		OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
		OpenForm(
		"Document.PriceSetup.Form.FormOfChangePricesNewVariant",
		OpeningParameters, ThisObject,,,, New CallbackDescription("ChangePricesNewOptionOnClientEnds",
		ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculatePricesUsingFormulaOnClientByCallType(CallingFromQuickAccessToolbar, PriceKind = Undefined)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",False);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",True);
	FillParameters.Insert("ConsiderCurrencyDifferences", False);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	If CallingFromQuickAccessToolbar Then
		CalculationParameters = FillInArrayForRecalculation(FillParameters, PriceKind);
		CalculatePricesOnClientCompletion(CalculationParameters);
	Else
		OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
		OpenForm(
			"Document.PriceSetup.Form.FormOfChangePricesNewVariant",
			OpeningParameters, ThisObject,,,, New CallbackDescription("ChangePricesNewOptionOnClientEnds",
			ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangePricesNewOption(Command)
	
	ChangePricesOnClientByCallType(False);
	
EndProcedure

&AtClient
Procedure ChangePricesByPercentageOnTheClientCompletion(Result, AdditionalParameters = Undefined) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = ChangePricesByPercentageOnServerInBackground(CalculationParameters);
																	
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else	
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			ChangePricesToPercentageOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf; 
			
	EndIf;

EndProcedure

&AtClient
Procedure ChangePricesOnClientEnd(Result, AdditionalParameters = Undefined) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = ChangeServerPricesInBackground(CalculationParameters);
			
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else	
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			ChangePricesOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf; 
		
	EndIf;

EndProcedure

&AtClient
Procedure CalculatePricesOnClientCompletion(Result, AdditionalParameters = Undefined) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = CalculateServerPricesInBackground(CalculationParameters);
																	
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else	
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			CalculatePricesOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf; 
		
	EndIf;

EndProcedure

&AtClient
Procedure ChangePricesNewOptionOnClientEnds(Result, AdditionalParameters = Undefined) Export
	
	If Result <> Undefined Then
	
		If Result.OptionToChangeThePrice = 1 Then
			ChangePricesByPercentageOnTheClientCompletion(Result, AdditionalParameters);
		ElsIf Result.OptionToChangeThePrice = 2 Or Result.OptionToChangeThePrice = 3 Then
			ChangePricesOnClientEnd(Result, AdditionalParameters) ;
		ElsIf Result.OptionToChangeThePrice = 4 Then
			RoundManualPricesCompletion(Result, AdditionalParameters);
		ElsIf Result.OptionToChangeThePrice = 5 Then
			CalculatePricesOnClientCompletion(Result, AdditionalParameters);
		EndIf;
 	
 	EndIf;
 	
EndProcedure

&AtServer
Function ChangeServerPricesInBackground(Val CalculationParameters)
	
	// we prepare the data for launching a long-term filling operation
	// and put the necessary form data into the structure
	ShapeStructure = InitializeFormStructure();
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("CalculationParameters"		, CalculationParameters);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.ChangePricesOnServer",
											JobParameters,
											ExecutionParameters);
	
EndFunction

&AtServer
Function FillInPricesFromDocumentsOnServerInBackground(Val CalculationParameters)
	
	// we prepare the data for launching a long-term filling operation
	// and put the necessary form data into the structure
	ShapeStructure = InitializeFormStructure();
	ShapeStructure.Insert("DataLayoutSettingsTable"		, GetFromTempStorage(StorageAddressDataLayoutSettings));	
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("CalculationParameters"		, CalculationParameters);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.FillInPricesFromDocuments",
											JobParameters,
											ExecutionParameters);
	
EndFunction

&AtServer
Function CalculateServerPricesInBackground(Val CalculationParameters, Val ConvertDCSForPriceTypes = False)
	
	// preparing the data to start a long-term filling operation
	ShapeStructure = InitializeFormStructure();	
	ShapeStructure.Insert("DataLayoutSettingsTable"		, GetFromTempStorage(StorageAddressDataLayoutSettings));	
	
	// to transfer to background tasks, we convert the addresses of the data layout scheme into objects, because in background sessions, temporary storage at addresses will not be available
	// because an additional operation is formed only for cases when it is really necessary
	If ConvertDCSForPriceTypes Then
	
		ShapeStructure.SelectedPrices.Columns.Add("DataCompositionSchema");
	
		For Each PriceTypeLine In ShapeStructure.SelectedPrices Do	
			
			Schema = New ValueStorage(GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchema));
			PriceTypeLine.DataCompositionSchema	= Schema.Get();
		
		EndDo; 			
	
	EndIf;
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("CalculationParameters"		, CalculationParameters);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.CalculatePricesOnServer",
											JobParameters,
											ExecutionParameters);
	
EndFunction

&AtServer
Function ChangePricesByPercentageOnServerInBackground(Val CalculationParameters)
	
	// preparing the data to start a long-term filling operation
	ShapeStructure = InitializeFormStructure();
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("CalculationParameters"		, CalculationParameters);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.ChangePricesToPercentageOnServer",
											JobParameters,
											ExecutionParameters);
	
EndFunction

&AtClient
Function RunAsynchronously(Val CalculationParameters)
	
	Return Not (CalculationParameters.SelectedLinesOnly Or (PriceTree.GetItems().Count() < 30));

EndFunction

&AtClient
Procedure ImportValidPrices(Command)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices", True);
	FillParameters.Insert("RoundingUpManualPrices",False);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",False);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
	
	If OpeningParameters.ManualPriceViews.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dạng giá được ấn định thủ công.';
										|ru = 'Не выбраны виды цен, назначаемые вручную.';
										|en = 'Price types assigned manually are not selected.'; fa = 'Price types assigned manually are not selected.';
										|it = 'Non sono stati selezionati i prezzi inseriti manualmente.';
										|pl = 'Nie wybrano rodzajów cen, ustalanych ręcznie.';
										|tr = 'Manuel olarak atanan fiyat türleri seçilmedi.'"));
		Return;
	EndIf;
	
	OpenForm(
		"Document.PriceSetup.Form.SelectPriceCalculationParameters",
		OpeningParameters,
		ThisObject,,,, New CallbackDescription("ImportValidPricesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportValidPricesCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = CalculateServerPricesInBackground(CalculationParameters);
																	
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else	
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			CalculatePricesOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf; 	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromDocuments(Command)
	
	OpenForm(
		"Document.PriceSetup.Form.DocumentChoiceForm",
		,
		ThisObject,,,, New CallbackDescription("ImportFromDocumentsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure ImportFromDocumentsCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Or Result.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ArrayOfPriceTypes = New Array();
	
	For Each PriceKind In SelectedPrices Do
		If PriceKind.Selected_5 Then
			ArrayOfPriceTypes.Add(PriceKind.Ref);
		EndIf;
	EndDo;
	
	SetVisibilityOfEditColumns(ThisObject, True);
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Documents", Result);
	CalculationParameters.Insert("TypesOfPrices",   ArrayOfPriceTypes);
		
	ResultOfCalculatingALongOperation = FillInPricesFromDocumentsOnServerInBackground(CalculationParameters);
															
	JobID						= ResultOfCalculatingALongOperation.JobID;
	AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
	
	If ResultOfCalculatingALongOperation.Status = "Completed2" Then
		
		ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
		
	Else	
		
		OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
		
	EndIf;                                                                       			
	
EndProcedure

&AtClient
Procedure RoundManualPrices(Command)
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",True);
	FillParameters.Insert("CalculationOfInformationSecurity", False);
	FillParameters.Insert("CalculationByFormulas",False);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	OpeningParameters = ParametersForOpeningCalculationParametersSelectionForm(FillParameters);
	If OpeningParameters.ManualPriceViews.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dạng giá được ấn định thủ công.';
										|ru = 'Не выбраны виды цен, назначаемые вручную.';
										|en = 'Price types assigned manually are not selected.'; fa = 'Price types assigned manually are not selected.';
										|it = 'Non sono stati selezionati i prezzi inseriti manualmente.';
										|pl = 'Nie wybrano rodzajów cen, ustalanych ręcznie.';
										|tr = 'Manuel olarak atanan fiyat türleri seçilmedi.'"));
		Return;
	EndIf;
	
	CalculationParameters = Undefined;
	
	OpenForm("Document.PriceSetup.Form.SelectPriceCalculationParameters", OpeningParameters, ThisObject,,,, New CallbackDescription("RoundManualPricesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RoundManualPricesCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = CalculateServerPricesInBackground(CalculationParameters);
																	
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else	
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			CalculatePricesOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf; 	
		
	EndIf;

EndProcedure

&AtClient
Procedure Calculate(Command)
	
	If Not SettingPricesClient.RequiredDataLayoutSchemaParametersFilledIn(ThisObject) Then
		Return;
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("ImportOldPrices",False);
	FillParameters.Insert("RoundingUpManualPrices",False);
	FillParameters.Insert("CalculationOfInformationSecurity", True);
	FillParameters.Insert("CalculationByFormulas",True);
	FillParameters.Insert("ImportFromYandexMarket",False);
	FillParameters.Insert("LoadingFromOzon", False);
	
	OpenForm(
		"Document.PriceSetup.Form.SelectPriceCalculationParameters",
		ParametersForOpeningCalculationParametersSelectionForm(FillParameters),
		ThisObject,,,, New CallbackDescription("CalculateCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculateCompletion(Result, AdditionalParameters) Export
	
	CalculationParameters = Result;
	If CalculationParameters <> Undefined Then
		
		ClearMessages();
		SetVisibilityOfEditColumns(ThisObject, True);
		
		If RunAsynchronously(CalculationParameters) Then
			
			ResultOfCalculatingALongOperation = CalculateServerPricesInBackground(CalculationParameters, True);
																	
			JobID						= ResultOfCalculatingALongOperation.JobID;
			AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
			
			If ResultOfCalculatingALongOperation.Status = "Completed2" Then
				
				ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
				
			Else
				
				OpenPriceCalculationWaitingWindowInBackground("ChangePricesOnClientEndMain")
				
			EndIf;
			
		Else
			
			CalculatePricesOnServer(CalculationParameters);
			ChangePricesOnClientEndingSnippet();
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure GenerateReportOnPriceDynamics()
	
	If UsePriceManagementSystem25 Then
		SelectionLists_ = New Structure();
		SelectionLists_.Insert("ItemList", New ValueList);
		SelectionLists_.Insert("ListOfTSOCharacteristics", New ValueList);
		SelectionLists_.Insert("ListOfTSOSeries", New ValueList);
		SelectionLists_.Insert("ListOfTSOPackages", New ValueList);
		
		For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
			
			TSRow = PriceTree.FindByID(IDOfPriceTreeRow);

			RowIsHierarchy = False;
			
			If TSRow.Property("ThisIsHierarchy", RowIsHierarchy) And RowIsHierarchy Then
				GoThroughHierarchy(SelectionLists_, TSRow.GetItems());
			Else
				SetListsForSelection(SelectionLists_, TSRow);
			EndIf;
			
		EndDo;
		
		ListOfPriceTypes = New ValueList;
		For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			ListOfPriceTypes.Add(PriceTypeLine.Ref, PriceTypeLine.Description);
		EndDo;
		
		Filter = New Structure;
		Filter.Insert("Products", SelectionLists_.ItemList);
		If SelectionLists_.ListOfTSOCharacteristics.Count() Then
			Filter.Insert("PricingVariant", SelectionLists_.ListOfTSOCharacteristics);
		EndIf;	
		If SelectionLists_.ListOfTSOSeries.Count() Then
			Filter.Insert("PricingBatch", SelectionLists_.ListOfTSOSeries);
		EndIf;	
		If SelectionLists_.ListOfTSOPackages.Count() Then
			Filter.Insert("PricingPackage", SelectionLists_.ListOfTSOPackages);
		EndIf;	
		Filter.Insert("PriceKind", ListOfPriceTypes);
		
		FormParameters = New Structure();
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.TrendsOfItemPrices2_5.Form",
			FormParameters,
			ThisObject,
			New UUID);
	Else
		ItemList  = New ValueList;
		ListOfCharacteristics = New ValueList;
		For Each IDOfPriceTreeRow In Items.PriceTree.SelectedRows Do
			TSRow = PriceTree.FindByID(IDOfPriceTreeRow);
			ItemList.Add(TSRow.Products);
			If TSRow.ItemVariantsAreUsed Then
				If TSRow.GetParent() = Undefined Then
					For Each StringCharacteristic In TSRow.GetItems() Do
						If ListOfCharacteristics.FindByValue(StringCharacteristic.Characteristic) = Undefined Then
							ListOfCharacteristics.Add(StringCharacteristic.Characteristic);
						EndIf;
					EndDo;
				Else
					If ListOfCharacteristics.FindByValue(TSRow.Characteristic) = Undefined Then
						ListOfCharacteristics.Add(TSRow.Characteristic);
					EndIf;
				EndIf;
			Else
				If ListOfCharacteristics.FindByValue(
						PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef")) = Undefined Then
					ListOfCharacteristics.Add(PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
				EndIf;
			EndIf;
		EndDo;
		
		ListOfPriceTypes = New ValueList;
		For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			ListOfPriceTypes.Add(PriceTypeLine.Ref, PriceTypeLine.Description);
		EndDo;
		
		Filter = New Structure;
		Filter.Insert("Products", ItemList);
		Filter.Insert("Characteristic", ListOfCharacteristics);
		Filter.Insert("PriceKind", ListOfPriceTypes);
		
		FormParameters = New Structure();
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
		FormParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.TrendsOfItemPrices.Form",
			FormParameters,
			ThisObject,
			New UUID);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure SalesDynamicsReport(Command)
	
	GenerateReportOnPriceDynamics();
	
EndProcedure

&AtClient
Procedure ExportToExcel(Command)
	
	ClearMessages();
	
	If PriceTree.GetItems().Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không có mặt hàng trong bảng giá';
												|ru = 'В прайс-листе отсутствуют позиции номенклатуры';
												|en = 'No product items in the price list'; fa = 'No product items in the price list';
												|it = 'Non ci sono le voci di articolo nel listino prezzi';
												|pl = 'W cenniku nie ma żadnych pozycji nomenklatury';
												|tr = 'Fiyat listesinde öğe pozisyonları bulunmamaktadır'"),,"PriceTree");
		Return;
	EndIf;
	
	Notification = New CallbackDescription("UploadExtensionCompletionToExcel", ThisObject);
	MessageText = NStr("vi = 'Để kết xuất ra Excel, cần cài đặt phần mở rộng tệp.';
						|ru = 'Для выгрузки в Excel необходимо установить расширение работы с файлами.';
						|en = 'To export data to Excel, install 1C:Enterprise Extension.'; fa = 'To export data to Excel, install 1C:Enterprise Extension.';
						|it = 'Per l''importazione in Excel è necessario installare l''estensione di lavoro con i file.';
						|pl = 'W celu eksportowanie do Excelu należy zainstalować rozszerzenie do pracy z plikami.';
						|tr = 'Excel''e aktarmak için dosya yönetimi uzantısı yapılandırmanız gerekmektedir.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
	
EndProcedure

&AtClient
Procedure UploadExtensionCompletionToExcel(Result, AdditionalParameters) Export
	
	If AttachFileSystemExtension()Then
		
		AddressDataForPrintingInTheTemporaryStorage = AddressInTemporaryPrintDataStore();
	
		ConfigurationFormParameters = New Structure(
			"DocumentsArray, UUID, AddressDataForPrintingInTheTemporaryStorage",
			Undefined,
			UUID,
			AddressDataForPrintingInTheTemporaryStorage);
		
		PrintParameters = Undefined;
		
		OpenForm(
			"Document.PriceSetup.Form.SelectItemsPrices",
			ConfigurationFormParameters,,,,, New CallbackDescription("UploadToExcelEnd", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Chưa kết nối phần mở rộng làm việc với tệp.';
										|ru = 'Расширение работы с файлами не подключено.';
										|en = '1C:Enterprise Extension is not attached.'; fa = '1C:Enterprise Extension is not attached.';
										|it = 'L''estensione di lavoro con i file non è abilitata.';
										|pl = 'Rozszerzenie pracy z plikami nie jest podłączone.';
										|tr = 'Dosya yönetimi uzantısı bağlı değil.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadToExcelEnd(Result, AdditionalParameters) Export
	
	PrintParameters = Result;
	
	If PrintParameters <> Undefined Then
		If PrintParameters.NumberOfSelectdPriceTypes = 0 Then
			ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dạng giá để kết xuất vào Excel.';
											|ru = 'Не выбраны виды цен для выгрузки в Excel.';
											|en = 'Price types to export to Excel are not selected.'; fa = 'Price types to export to Excel are not selected.';
											|it = 'Не выбраны виды цен для выгрузки в Excel.';
											|pl = 'Price types to export to Excel are not selected.';
											|tr = 'Excel''e yüklemek için fiyat türü seçilmedi.'"));
			Return;
		EndIf;
		PrintParameters.DisplayHeader = False;
		
		#If WebClient Then
			
			SettingPricesClient.UploadToExcelWithoutWEBLink(ThisObject, PrintParameters);
			
		#Else	
			
			SettingPricesClient.UploadToExcelWithoutLink(ThisObject, PrintParameters);
			
		#EndIf
		
	EndIf;

EndProcedure

&AtClient
Procedure ImportFromExcel(Command)
	
	Notification = New CallbackDescription("DownloadFromExcelCompletionOfExtensionConnection", ThisObject);
	MessageText = NStr("vi = 'Để kết nhập từ Excel, cần cài đặt phần mở rộng làm việc với tệp.';
						|ru = 'Для загрузки из Excel необходимо установить расширение работы с файлами.';
						|en = 'To import data from Excel, install 1C:Enterprise Extension.'; fa = 'To import data from Excel, install 1C:Enterprise Extension.';
						|it = 'Per il download da Excel è necessario installare l''estensione di lavoro con i file.';
						|pl = 'W celu importowania z Excelu należy zainstalować rozszerzenie do pracy z plikami.';
						|tr = 'Excel''e yüklemek için dosya yönetimi uzantısı yapılandırmanız gerekmektedir.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
	
EndProcedure

&AtClient
Procedure DownloadFromExcelCompletionOfExtensionConnection(Result, AdditionalParameters) Export
	
	If AttachFileSystemExtension()Then

		#If WebClient Then

			SettingPricesClient.DownloadFromExcelWithoutWEBLink(ThisObject);
			
		#Else	

			SettingPricesClient.DownloadFromExcelWithoutLink(ThisObject);
	
		#EndIf
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Chưa kết nối phần mở rộng làm việc với tệp.';
										|ru = 'Расширение работы с файлами не подключено.';
										|en = '1C:Enterprise Extension is not attached.'; fa = '1C:Enterprise Extension is not attached.';
										|it = 'L''estensione di lavoro con i file non è abilitata.';
										|pl = 'Rozszerzenie pracy z plikami nie jest podłączone.';
										|tr = 'Dosya yönetimi uzantısı bağlı değil.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintPriceList(Command)
	
	OpeningParameters = New Structure;
	
	NewSettings1 = Undefined;
	GetSettings(NewSettings1);
	
	ListTypesOfPrices = New ValueList;
	ListTypesOfPrices.LoadValues(SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	
	Filter = New Structure;
	Filter.Insert("TypesOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	Filter.Insert("ReportDate", Date);
	
	OpeningParameters.Insert("FixedSettings", NewSettings1);
	OpeningParameters.Insert("VariantKey", "PriceListContext");
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("Filter", Filter);
	OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	If (UsePriceManagementSystem25) Then
		OpenForm(
			"Report.PriceList2_5.ObjectForm",
			OpeningParameters,
			ThisObject,
			True);
	Else
		OpenForm(
			"Report.PriceList.ObjectForm",
			OpeningParameters,
			ThisObject,
			True);
	EndIf;
		
EndProcedure

&AtClient
Procedure PriceChangeHistoryContext(Command)
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Key",           CurrentData.Products);
	FormOpenParameters.Insert("Characteristic", CurrentData.Characteristic);
	
	OpenForm("Catalog.Products.Form.PricesHistoryOfItemsAndService", FormOpenParameters);
	
EndProcedure

&AtClient
Procedure ToCompleteThePriceChange(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		RecordPriceChanges();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Generate(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		OpenPriceListSettingsForm(Not UseSeveralPriceTypes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsWithSimilarProperties(Command)
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	GoodsWithSimilarProperties = New Structure;
	GoodsWithSimilarProperties.Insert("Products", CurrentData.Products);
	GoodsWithSimilarProperties.Insert("Characteristic", CurrentData.Characteristic);
	OpenPriceListSettingsForm(Not UseSeveralPriceTypes, GoodsWithSimilarProperties);
	
EndProcedure

&AtClient
Procedure CancelPriceChange(Command)
	
	SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");	
	If SubstringPosition <> 0 Then
		CurColumnName = Right(Items.PriceTree.CurrentItem.Name, StrLen(Items.PriceTree.CurrentItem.Name) - SubstringPosition + 1);			
	EndIf;
	
	CancelPriceChangesOnServer();
	OpenWaitingWindowApplySettingsInBackground();
	
EndProcedure

&AtClient
Procedure PrintRevaluationInRetail(Command)
	
	PriceChangeSessionIsActive = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("Date", Date);
	
	OpenForm(
		"DataProcessor.PriceList.Form.PriceApplicationForm",
		FormParameters,
		ThisObject,,,, New CallbackDescription("PrintRevaluationInRetailCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PrintRevaluationInRetailCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DocumentsArray = New Array;
	If Modified Then
		DocumentsArray = RecordPriceChangesOnServer(Result.Comment, Result.PriceApplicationOption);
	Else
		For Each TSRow In SavedDocuments Do
			StructureOfDocuments = New Structure;
			StructureOfDocuments.Insert("PriceSetup", TSRow.Ref);
			StructureOfDocuments.Insert("PriceApproval", Undefined);
			DocumentsArray.Add(StructureOfDocuments);
		EndDo;
	EndIf;
	
	If DocumentsArray = Undefined
		Or DocumentsArray.Count() = 0 Then
		
		PrintObjects = New Array;
		PrintObjects.Add(PredefinedValue("Document.PriceSetup.EmptyRef"));
		
		CommandDetails = New Structure;
		CommandDetails.Insert("PrintObjects", PrintObjects);
		CommandDetails.Insert("Form", ThisObject);
		
		PrintManagementTMClient.PrintRevaluationInRetail(CommandDetails, AddressInTemporaryPrintDataStore());
		
	Else
		
		ProductPriceSettingDocuments = New Array;
		For Each TSRow In DocumentsArray Do
			ProductPriceSettingDocuments.Add(TSRow.PriceSetup);
		EndDo;
		
		CommandDetails = New Structure;
		CommandDetails.Insert("PrintObjects", ProductPriceSettingDocuments);
		CommandDetails.Insert("Form", ThisObject);
		
		PrintManagementTMClient.PrintRevaluationInRetail(CommandDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintProductPricing(Command)
	
	PriceChangeSessionIsActive = False;
	
	If Modified Then
		FormParameters = New Structure();
		FormParameters.Insert("Date", Date);
		
		OpenForm(
			"DataProcessor.PriceList.Form.PriceApplicationForm",
			FormParameters,
			ThisObject,,,, New CallbackDescription("PrintProductPricingCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	Else
		Result = New Structure;
		PrintProductPricingCompletion(Result, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintProductPricingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DocumentsArray = New Array;
	If Modified Then
		DocumentsArray = RecordPriceChangesOnServer(Result.Comment, Result.PriceApplicationOption);
	Else
		For Each TSRow In SavedDocuments Do
			StructureOfDocuments = New Structure;
			StructureOfDocuments.Insert("PriceSetup", TSRow.Ref);
			StructureOfDocuments.Insert("PriceApproval", Undefined);
			DocumentsArray.Add(StructureOfDocuments);
		EndDo;
	EndIf;
	
	If DocumentsArray = Undefined
		Or DocumentsArray.Count() = 0 Then
		
		PrintObjects = New Array;
		PrintObjects.Add(PredefinedValue("Document.PriceSetup.EmptyRef"));
		
		CommandDetails = New Structure;
		CommandDetails.Insert("PrintObjects", PrintObjects);
		CommandDetails.Insert("Form", ThisObject);
		
		PrintManagementTMClient.PrintProductPricing(CommandDetails, AddressInTemporaryPrintDataStore());
		
	Else
		
		ProductPriceSettingDocuments = New Array;
		For Each TSRow In DocumentsArray Do
			ProductPriceSettingDocuments.Add(TSRow.PriceSetup);
		EndDo;
		
		CommandDetails = New Structure;
		CommandDetails.Insert("PrintObjects", ProductPriceSettingDocuments);
		CommandDetails.Insert("Form", ThisObject);
		
		PrintManagementTMClient.PrintProductPricing(CommandDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintPriceTags(Command)
	
	AddressInStorage = DataForPrintingPriceTags();
	
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
		New Structure("AddressInStorage, TemplateAssignment", AddressInStorage, Undefined),
		ThisObject,
		New UUID);
	
EndProcedure

&AtClient
Procedure PrintLabel(Command)
	
	AddressInStorage = LabelPrintingData();
	
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
		New Structure("AddressInStorage, TemplateAssignment", AddressInStorage, Undefined),
		ThisObject,
		New UUID);
	
EndProcedure

&AtClient
Procedure PriceChangeHistory(Command)
	
	OpenForm("Document.PriceSetup.ListForm");
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SetUpDisplayedInformation(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ShowPriceChange",   				ShowPriceChange);
	FormParameters.Insert("ShowMarkupPercent",  				ShowMarkupPercent);
	FormParameters.Insert("ShowEffectivePrices", 				ShowEffectivePrices);
	FormParameters.Insert("ValidPriceDate",        				ValidPriceDate);
	FormParameters.Insert("ShowTheQuickEditPanel",	ShowTheQuickEditPanel);
	FormParameters.Insert("ShowFormulas", 						ShowFormulas);
	FormParameters.Insert("ShowCurrency", 						ShowCurrency);
	FormParameters.Insert("ShowUnitsOfMeasurement", 				ShowUnitsOfMeasurement);
	FormParameters.Insert("CalculateAutomatically",				CalculateAutomatically);
	FormParameters.Insert("ShowInfluencingPrices",					ShowInfluencingPrices);
	FormParameters.Insert("UseOneColumnForThePriceKey",		UseOneColumnForThePriceKey);
	FormParameters.Insert("FixTheItemColumn",			FixTheItemColumn);
	FormParameters.Insert("ShowDate",							True);
	If UsePriceManagementSystem25 Then
		FormParameters.Insert("ShowVATRate", 					ShowVATRate);
	EndIf;

	OpenForm(
		"DataProcessor.PriceList.Form.SettingsFormOfDisplayedInformation",
		FormParameters,
		ThisObject,,,, New CallbackDescription("SetUpDisplayedInformationCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetUpDisplayedInformationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ShowPriceChange   				= Result.ShowPriceChange;
	ShowMarkupPercent  				= Result.ShowMarkupPercent;
	ShowEffectivePrices 				= Result.ShowEffectivePrices;
	ValidPriceDate        				= Result.ValidPriceDate;
	ShowTheQuickEditPanel	= Result.ShowTheQuickEditPanel;
	ShowFormulas 						= Result.ShowFormulas;
	ShowCurrency 						= Result.ShowCurrency;
	ShowUnitsOfMeasurement 				= Result.ShowUnitsOfMeasurement;
	CalculateAutomatically				= Result.CalculateAutomatically;
	FixTheItemColumn		= Result.FixTheItemColumn;
	ShowVATRate						= Result.ShowVATRate;
	
	SetCountAutomaticallyOnClient(CalculateAutomatically);
	FixTheItemColumn(FixTheItemColumn);

	If ShowInfluencingPrices <> Result.ShowInfluencingPrices Then
		ShowInfluencingPrices = Result.ShowInfluencingPrices;
		DisplayInfluencingPricesOnClient(ShowInfluencingPrices);	
	EndIf;
	
	SetQuickEditVisibility(ThisObject);
	
	SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
	
	If UseOneColumnForThePriceKey <> Result.UseOneColumnForThePriceKey Then
		UseOneColumnForThePriceKey = Result.UseOneColumnForThePriceKey;
		ConfigurePriceKeyColumns();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateSettingsForPriceTypes(Command = Undefined)

	If Items.PriceTree.CurrentData <> Undefined Then
		CurrentProducts = Items.PriceTree.CurrentData.Products;
	Else
		CurrentProducts = Undefined;
	EndIf;

	UpdateSettingsForPriceTypesOnServer();
	SelectedPricesWereChanged = (PriceTree.GetItems().Count() > 0);
	
	If CurrentProducts <> Undefined Then

		For Each TreeRow In PriceTree.GetItems() Do
			
			If TreeRow.Products = CurrentProducts Then
				Items.PriceTree.CurrentRow = TreeRow.GetID();
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadFromYandexMarket(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DownloadFromOzon(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)
	
	SettingPricesClient.OpenVATRatesForm(ThisObject, Date);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDisplaySettings(SavedSettings)
	
	SettingKind               = SavedSettings.SettingKind;
	NavigationOption           = SavedSettings.NavigationOption;
	ProductKind            = SavedSettings.ProductKind;
	ShowVATRate        = SavedSettings.ShowVATRate;
	
	SavedSettings.Property("OptionForSettingThePrice", OptionForSettingThePrice);
	SavedSettings.Property("GroupingOption", GroupingOption);
	SavedSettings.Property("ShowMarkupPercent", ShowMarkupPercent);
	SavedSettings.Property("ShowPriceChange", ShowPriceChange);
	SavedSettings.Property("ShowEffectivePrices", ShowEffectivePrices);
	SavedSettings.Property("ValidPriceDate", ValidPriceDate);
	SavedSettings.Property("ShowFormulas", ShowFormulas);
	SavedSettings.Property("ShowTheQuickEditPanel", ShowTheQuickEditPanel);
	SavedSettings.Property("ShowCurrency", ShowCurrency);

	If SavedSettings.Property("ShowCurrency") Then
		ShowCurrency = SavedSettings.ShowCurrency And GetFunctionalOption("UseMultipleCurrencies");
	Else
		ShowCurrency = GetFunctionalOption("UseMultipleCurrencies");
	EndIf;
	
	SavedSettings.Property("ShowUnitsOfMeasurement", ShowUnitsOfMeasurement);
	SavedSettings.Property("CalculateAutomatically", CalculateAutomatically);
	SavedSettings.Property("ShowInfluencingPrices", ShowInfluencingPrices);
	SavedSettings.Property("UseOneColumnForThePriceKey", UseOneColumnForThePriceKey);
	SavedSettings.Property("FixTheItemColumn", FixTheItemColumn);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeProductKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Show", False);
	
	// do not show measurements when output when 1 column is used for the price key
	// for the item
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingVariant");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);
	
	// For the characteristic
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePricingVariant.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);	
	
	// For the Series
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePricingBatch.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOneColumnForThePriceKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PricingPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Show", False);	
	 
EndProcedure

&AtServer
Procedure GetSettings(NewSettings1)
	
	NewSettings1 = SettingsComposerFilter.GetSettings();
	
	ListOfPriceTypes = New ValueList;
	ListOfPriceTypes.LoadValues(SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	
	For Each FilterElement In NewSettings1.Filter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
			And FilterElement.LeftValue = New DataCompositionField("OnlyInStock") Then
			
			If FilterElement.Use
				And FilterElement.RightValue = True Then
			
				FilterElement.LeftValue = New DataCompositionField("Balance");
				FilterElement.ComparisonType = DataCompositionComparisonType.Greater;
				FilterElement.RightValue = 0;
				
			Else
				
				NewSettings1.Filter.Items.Delete(FilterElement);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	FilterElement = NewSettings1.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("PriceKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = ListOfPriceTypes;
	FilterElement.Use = True;
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	StructureOfData = SettingPricesClientServer.NewFormSettingsStructure();

	If SaveAllSettings Then
		ComposerSettings = SettingsComposerFilter.GetSettings();
		ColumnComposerSettings = SettingsBuilderColumnSelection.GetSettings();
		SelectedPricesTable = SettingPricesServer.SelectedTypesOfPricesInTable(ThisObject);
		ArrayOfSelectedPrices = SettingPricesClientServer.SelectedTypesOfPrices(ThisObject);
		
		StructureOfData.ComposerSettings 				= ComposerSettings;
		StructureOfData.ColumnComposerSettings 		= ColumnComposerSettings;
		StructureOfData.SelectedPrices 						= ArrayOfSelectedPrices;
		StructureOfData.SelectedPricesTable				= SelectedPricesTable;
		StructureOfData.FilterParametersTable 			= FilterParametersTable.Unload();
		StructureOfData.FilterSettingsAreSet 			= FilterSettingsAreSet;
		StructureOfData.ValidPriceDate 					= ValidPriceDate;
	Else
		SavedSettingsFromStorage = Common.CommonSettingsStorageLoad("DataProcessor.PriceList", "DataProcessor.PriceList");
		If SavedSettingsFromStorage <> Undefined Then
			FillPropertyValues(StructureOfData, SavedSettingsFromStorage);
		EndIf;
	EndIf;
	
	StructureOfData.SettingKind 							= SettingKind;
	StructureOfData.NavigationOption 						= NavigationOption;
	StructureOfData.GroupingOption 						= GroupingOption;
	StructureOfData.ProductKind 						= ProductKind;
	StructureOfData.ShowEffectivePrices 				= ShowEffectivePrices;
	StructureOfData.ShowPriceChange 				= ShowPriceChange;
	StructureOfData.ShowMarkupPercent 				= ShowMarkupPercent;
	StructureOfData.ShowFormulas 						= ShowFormulas;
	StructureOfData.ShowCurrency 						= ShowCurrency;
	StructureOfData.ShowUnitsOfMeasurement 				= ShowUnitsOfMeasurement;
	StructureOfData.CalculateAutomatically 				= CalculateAutomatically;
	StructureOfData.ShowInfluencingPrices 					= ShowInfluencingPrices;
	StructureOfData.UseOneColumnForThePriceKey 		= UseOneColumnForThePriceKey;
	StructureOfData.OptionForSettingThePrice 		= OptionForSettingThePrice;
	StructureOfData.FixTheItemColumn 		= FixTheItemColumn;
	StructureOfData.ShowTheQuickEditPanel 	= ShowTheQuickEditPanel;
	StructureOfData.ShowVATRate 					= ShowVATRate;
	
	Common.CommonSettingsStorageSave("DataProcessor.PriceList", "DataProcessor.PriceList", StructureOfData);
	
EndProcedure

&AtClient
Procedure ShowWarningByPriceType(PriceKind)
	
	ClearMessages();
	
	If PriceKind = Undefined Then
		InformationBar = "";
		WarningString = NStr("vi = 'Để áp dụng tùy chọn của thanh soạn nhanh, cần chọn dạng giá bằng cách chọn ô trong cột dạng giá được soạn.';
							|ru = 'Для применения опций панели быстрого редактирования необходимо выбрать вид цен выделением ячейки в колонке вида редактируемых цен.';
							|en = 'To apply the quick editing bar options, select the prices type by selecting a cell in the column of the edited prices type.'; fa = 'To apply the quick editing bar options, select the prices type by selecting a cell in the column of the edited prices type.';
							|it = 'Per l''applicazione delle opzioni del pannello di modifica rapida, è necessario selezionare il tipo di prezzo evidenziando la cella nella colonna del tipo di prezzi modificabili.';
							|pl = 'W celu zastosowania opcji panelu szybkiej edycji należy wybrać rodzaj cen odróżnieniem komórki w kolumnie rodzaju edytowanych cen.';
							|tr = 'Hızlı düzenleme paneli seçeneklerinin uygulanması için düzenlenen fiyat türü sütununda hücre belirterek fiyat tipini seçmeniz gerekmektedir.'");
	Else
		WarningString = NStr("vi = 'Chưa soạn dạng giá đã chọn.';
							|ru = 'Выбранный вид цен не редактируется.';
							|en = 'The selected price type cannot be edited.'; fa = 'The selected price type cannot be edited.';
							|it = 'Il tipo di prezzo selezionato non può essere modificato.';
							|pl = 'Wybrany rodzaj cen nie jest edytowany.';
							|tr = 'Seçilen fiyat türü düzenlenemez.'");
	EndIf;
	
	CommonClient.MessageToUser(WarningString);
	
EndProcedure

&AtServerNoContext
Function AllowChangingFormulas(PricingMethod)
	
	Return  Catalogs.TypesOfPrices.AllowChangingFormulas(PricingMethod); 
	
EndFunction

&AtClient
Procedure Apply(Command)

	SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");	
	If SubstringPosition <> 0 Then
		CurColumnName = Right(Items.PriceTree.CurrentItem.Name, StrLen(Items.PriceTree.CurrentItem.Name) - SubstringPosition + 1);			
	EndIf;
	
	PriceKind = GetPriceViewByColumnName(CurColumnName);
	
	If PriceKind <> Undefined And PriceKind.Edit Then
		
		If OptionToChangeThePrice = 1 Then // set the change to a percentage	
			
			ChangePricesByPercentageOnClientByCallType(True, PriceKind.Ref);
			
		ElsIf OptionToChangeThePrice = 2 Then // set amount change	
			
			ChangePricesOnClientByCallType(True, PriceKind.Ref);
			
		ElsIf OptionToChangeThePrice = 3 Then // set the amount
			
			ChangePricesOnClientByCallType(True, PriceKind.Ref);
			
		ElsIf OptionToChangeThePrice = 4 Then	// change formulas
			
			//replace with a new function
			If AllowChangingFormulas(PriceKind.PricingMethod) Then
				CalculatePricesUsingFormulaOnClientByCallType(True, PriceKind.Ref);
				MarkModifiedFormulasServer(PriceKind.Ref);
			Else
				UserMessage = NStr("vi = 'Đối với dạng giá có phương thức đặt đơn giá [%1], không thể tính theo công thức.
				|Để tính theo công thức, có thể sử dụng các dạng giá với phương thức đặt đơn giá như sau:';
				|ru = 'Для видов цен со способом задания цены [%1] не предусмотрен расчет по формулам.
				|Для расчета по формулам доступны виды цен со следующими спобами задания цены:';
				|en = 'Calculation using formulas is not provided for price types with the price setting method [%1].
				|Price types with the following price setting methods are available for calculation using formulas:'; fa = 'Calculation using formulas is not provided for price types with the price setting method [%1].
				|Price types with the following price setting methods are available for calculation using formulas:';
				|it = 'Per i tipi di prezzo con metodo di impostazione di prezzo [%1] non è previsto il calcolo per formule. 
				|Per il calcolo per formule sono disponibili tipi di prezzo con i seguenti metodi di impostazione di prezzo:';
				|pl = 'Dla rodzajów cen ze sposobem zadania ceny [%1] nie jest przewidziane obliczenie wg formuł.
				|Dla obliczenia wg formuł są dostępne rodzaje cen z następującymi sposobami zadania ceny:';
				|tr = '[%1] fiyat belirleme yöntemine sahip fiyat türlerinin formül hesaplaması bulunmamaktadır.
				|Formül hesaplaması için aşağıdaki fiyat belirleme yöntemlerine sahip fiyat türleri mevcuttur:'");
				UserMessage = StringFunctionsClientServer.SubstituteParametersToString(UserMessage, PriceKind.PricingMethod);
					ArrayOfAvailablePriceTypes = New Array;
					ArrayOfAvailablePriceTypes.Add(PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes"));
					ArrayOfAvailablePriceTypes.Add(PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup"));
					For Each It_ In ArrayOfAvailablePriceTypes Do
						PriceSettingMethodString = NStr("vi = '
						|[%1]';
						|ru = '
						|[%1]';
						|en = '
						|[%1]'; fa = '
						|[%1]';
						|it = '
						|[%1]';
						|pl = '
						|[%1]';
						|tr = '
						|[%1]'");
						PriceSettingMethodString = StringFunctionsClientServer.SubstituteParametersToString(PriceSettingMethodString, It_);
						UserMessage = UserMessage + PriceSettingMethodString;	
					EndDo;
				
				ClearMessages();
				CommonClient.MessageToUser(UserMessage);
			EndIf;
			
		EndIf;
		
	Else
		ShowWarningByPriceType(PriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeValueStringStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersOfPriceEditingForm_1(ChangeValueString), 
		Items.ChangeValueString,,,, 
		New CallbackDescription("FormulasConstructorCompletion_1", ThisObject), 
		FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

&AtServer
Procedure CancelPriceChangesOnServer(ClosingForm = False)
	
	SetPrivilegedMode(True);
	SettingPricesServer.ClearSavedDocuments(SavedDocuments, UUID, True);
	
	If Not ClosingForm Then
		SettingPricesServer.BuildPriceTree(ThisObject);
		SetVisibilityOfEditColumns(ThisObject, False);
		ApplySettings();
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteExceptionLinesByPriceTreeProductType(Tree, SelectionByBanValue, ArrayOfColumnNames, DeleteParent = False)
	
	IndexOf = Tree.Rows.Count() - 1;
	While IndexOf >= 0 Do
		Page1 = Tree.Rows.Get(IndexOf);
		
		If Page1.Rows.Count() > 0 Then
			DeleteExceptionLinesByPriceTreeProductType(Page1, SelectionByBanValue, ArrayOfColumnNames, DeleteParent);
			If DeleteParent Then
				Tree.Rows.Delete(Page1);
			EndIf;
		Else
			ExcellentValueFound = False;
			For Each Column In ArrayOfColumnNames Do
				If Page1[Column] <> SelectionByBanValue Then
					ExcellentValueFound = True;
					Continue;
				EndIf
			EndDo;
			If ExcellentValueFound Then
				Tree.Rows.Delete(Page1);
			EndIf;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	DeleteParent = (Tree.Rows.Count() = 0);
	
EndProcedure

// Select columns of price types to delete rows
// 
// Parameters:
// 	Tree - ValueTree - price tree.
&AtServer
Procedure AddSelectionBasedOnPriceSettingOption(Tree)
	
	If OptionForSettingThePrice = 1 Then //there must be a mouth.
		SelectionByBanValue = False;
	ElsIf OptionForSettingThePrice = 2 Then //there should be no mouth.
		SelectionByBanValue = True;
	EndIf;
	
	If SelectionByBanValue <> Undefined Then
		ArrayOfColumnNames = New Array;
		
		For Each Column In Tree.Columns Do
			If StrFind(Column.Name,"NoEditingAllowed")>0 Then
				ArrayOfColumnNames.Add(Column.Name);
			EndIf
		EndDo;
		
		DeleteExceptionLinesByPriceTreeProductType(Tree, SelectionByBanValue, ArrayOfColumnNames);
	EndIf;
	
EndProcedure

&AtServer
Procedure ApplySettings(AddressInTempStorage = Undefined, PriceListEditingData = Undefined)
	
	AddressOfDataCacheStorage = "";
	
	If AddressInTempStorage <> Undefined Then
		
		StructureOfData = GetFromTempStorage(AddressInTempStorage); // See SettingPricesClientServer.NewFormSettingsStructure
		
		SettingsComposerFilter.LoadSettings(StructureOfData.ComposerSettings);
		SettingPricesServer.ConfigureSelectionHeader(ThisObject);
		
		If StructureOfData.Property("ColumnComposerSettings") And ValueIsFilled(StructureOfData.ColumnComposerSettings) Then
			SettingsBuilderColumnSelection.LoadSettings(StructureOfData.ColumnComposerSettings);
		EndIf;
		
		For Each TSRow In StructureOfData.SelectedPrices Do	
			FormDataString = SettingPricesClientServer.FindPriceTypeString(SelectedPrices, TSRow[0]);
			If FormDataString <> Undefined Then
				FillPropertyValues(FormDataString, TSRow,, "AddressOfDataCompositionSchema, AddressOfDataCompositionSchemaSettings, AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem");
			EndIf;
		EndDo;
		
		SelectedPrices.Sort("AddlOrderingAttribute,Description");
		
		StructureOfData.Property("GroupingOption",GroupingOption);

		SelectedPrices.Sort("AddlOrderingAttribute");

		Date = StructureOfData.Date;
		
		SettingKind = StructureOfData.SettingKind;
		FilterParametersTable.Load(StructureOfData.FilterParametersTable);
		
		NavigationOption = StructureOfData.NavigationOption;
		ProductKind = StructureOfData.ProductKind;
		OptionForSettingThePrice = StructureOfData.OptionForSettingThePrice; 
		
		FilterSettingsAreSet = SettingsComposerFilter.Settings.Filter.Items.Count() > 0;
		
	EndIf;
	
	Items.PriceTreeProductKind.Visible = False;
	
	ColumnsToAdd = New Structure;
	If GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		ColumnsToAdd.Insert("HierarchyIsGroup",New TypeDescription("Boolean"));
		ColumnsToAdd.Insert("ThisIsHierarchy",New TypeDescription("Boolean"));
	ElsIf GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
		ColumnsToAdd.Insert("HierarchyIsGroup",New TypeDescription("Boolean"));
		ColumnsToAdd.Insert("ThisIsHierarchy",New TypeDescription("Boolean"));
		ColumnsToAdd.Insert("ProductKind",New TypeDescription("CatalogRef.ItemKinds"));
		Items.PriceTreeProducts.AutoMarkIncomplete = False;
		Items.PriceTreeProductKind.Visible = True;
	Else
		Items.PriceTreeProducts.AutoMarkIncomplete = True;
	EndIf;
	
	TreeDetails = GetAttributes("PriceTree");
	If ColumnsToAdd.Count() Then
		For Each TreeProps_ In TreeDetails Do
			If ColumnsToAdd.Property(TreeProps_.Name) Then
				ColumnsToAdd.Delete(TreeProps_.Name);
			EndIf; 
		EndDo;
		 
		For Each TreeColumn In ColumnsToAdd Do
			Array = New Array;
			Array.Add(New FormAttribute(TreeColumn.Key,TreeColumn.Value,"PriceTree"));
			ChangeAttributes(Array);
		EndDo;
	EndIf;
		
	
	Object.Goods.Clear();
	
	SetPriceCalculationOptions = New Array;
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares"));
	SetPriceCalculationOptions.Add(PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices"));
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields"   , New Array);
	SettingsStructure.Insert("DataParameters"    , New Structure);
	SettingsStructure.Insert("SettingsComposer", Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate" , Undefined);
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates" , False);
	SettingsStructure.Insert("PricesAsOfDate", EndOfDay(Date));
	SettingsStructure.Insert("DateOfReceiptOfBalances", Date);
	
	SettingsStructure.Insert("SelectionByTheOptionOfCalculatingThePricesOfSets", SetPriceCalculationOptions);
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UsePriceManagementSystem25          = PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);
	
	SettingsStructure.RequiredFields.Add("Products");
	If UsePriceManagementSystem25 Then
		If UseItemVariants Then
			SettingsStructure.RequiredFields.Add("Characteristic");
			SettingsStructure.RequiredFields.Add("PricingVariant");
		EndIf;
		If UseItemsBatch Then
			SettingsStructure.RequiredFields.Add("Series");
			SettingsStructure.RequiredFields.Add("PricingBatch");
		EndIf;
		If UseItemPackages Then
			SettingsStructure.RequiredFields.Add("PricingPackage");
		EndIf;
	Else	
		If UseItemVariants Then
			SettingsStructure.RequiredFields.Add("Characteristic");
		EndIf;
	EndIf;
	
	SettingsStructure.SettingsComposer = New Structure("Settings"	, SettingsComposerFilter.Settings);
	If UsePriceManagementSystem25 Then
		SettingsStructure.NameOfDataLayoutSchemaTemplate = "Template2_5";
	Else	
		SettingsStructure.NameOfDataLayoutSchemaTemplate = "Template";
	EndIf;
	
	SelectedPrices.Sort("AddlOrderingAttribute");
	SettingPricesServer.BuildPriceTree(ThisObject);
	SetVisibilityOfEditColumns(ThisObject, UseTheEditMode);
	
	// preparing the data to start a long-term filling operation
	ShapeStructure = InitializeFormStructure();
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("SettingsStructure"		, SettingsStructure);
	GenerationParameters.Insert("UUID", UUID);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	ResultOfCalculatingALongOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.ApplySettingsInBackground",
															JobParameters,
															ExecutionParameters);
														
	JobID						= ResultOfCalculatingALongOperation.JobID;
	AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
	
	If ResultOfCalculatingALongOperation.Status = "Completed2" Then
		ApplySettingsInBackgroundCompletion();
	EndIf;
	
EndProcedure

// Function to Initialize the structure of the shape
// Initializes structures with some form variables to pass to background tasks.
//
// Returns:
// Structure
// Strukturformel - filled structure with a variable shape (not all variables).
//
&AtServer
Function InitializeFormStructure()
	
	// we put the necessary form data into the structure
	ShapeStructure  = New Structure();
	ShapeStructure.Insert("Date"   								, Date);
	ShapeStructure.Insert("ValidPriceDate"					, ValidPriceDate);
	ShapeStructure.Insert("Modified"					, Modified);
	ShapeStructure.Insert("Object"   								, New Structure());
	ShapeStructure.Insert("FormCode" 								, FormCode);
	ShapeStructure.Insert("SelectedPrices" 						, FormAttributeToValue("SelectedPrices"));
	ShapeStructure.Insert("PriceTree"								, FormAttributeToValue("PriceTree"));
	ShapeStructure.Insert("CalculateAutomatically" 			, CalculateAutomatically);
	ShapeStructure.Insert("UseItemPackages"    	, UseItemPackages);
	ShapeStructure.Insert("UseItemVariants", UseItemVariants);
	ShapeStructure.Insert("UseItemsBatch"         , UseItemsBatch);
	ShapeStructure.Insert("NumberOfRowsInThePriceTree"				, NumberOfRowsInThePriceTree);
	ShapeStructure.Insert("GroupingOption"					, GroupingOption);
	ShapeStructure.Insert("UsePriceManagementSystem25"			, UsePriceManagementSystem25);
	ShapeStructure.Insert("AddressOfDataCacheStorage"				, "");
	ShapeStructure.Insert("UUID"				, UUID);
	
	Return ShapeStructure;

EndFunction

&AtServer
Function RecordPriceChangesOnServer(Comment = "", PriceApplicationOption = 0)
	
	Data	= Documents.PriceSetup.RecordPriceChangesOnServer(ThisObject, Comment, PriceApplicationOption); 
	SetVisibilityOfEditColumns(ThisObject, False);
	
	Return Data;
	
EndFunction

&AtClient
Procedure RecordPriceChanges()
	
	PriceChangeSessionIsActive = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("PriceStartDate", Date);
	FormParameters.Insert("MarketingActivity", MarketingActivity);
	FormParameters.Insert("TheseArePricesWithAnExpirationDate", SetTemporaryPrices);
	FormParameters.Insert("EndDateOfThePricePeriod", EndDateOfThePricePeriod);
	FormParameters.Insert("ListOfPricingOptions", Items.SetTemporaryPrices.ChoiceList.Copy());
	
	OpenForm(
		"DataProcessor.PriceList.Form.PriceApplicationForm",
		FormParameters,
		ThisObject,,,, New CallbackDescription("RecordPriceChangesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RecordPriceChangesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If SetTemporaryPrices <> Result.TheseArePricesWithAnExpirationDate Then
		SetTemporaryPrices 	= Result.TheseArePricesWithAnExpirationDate;
	EndIf; 
	
	Date								= Result.PriceStartDate;
	EndDateOfThePricePeriod	= Result.PriceExpirationDate;
	MarketingActivity			= Result.MarketingActivity;
	SetTemporaryPricesWhenChangingOnServer(ThisObject);
	
	If SetTemporaryPrices And EndDateOfThePricePeriod <= Date Then
		MessageText = NStr("vi = 'Ngày kết thúc kỳ hiệu lực của đơn giá phải lớn hơn ngày đầu kỳ.
			|Chứng từ chưa được ghi lại.';
			|ru = 'Дата завершения периода действия цен должна быть больше начала периода.
			|Документы не записаны.';
			|en = 'The price validity period end date must be greater than the period start.
			|Documents are not saved.'; fa = 'The price validity period end date must be greater than the period start.
			|Documents are not saved.';
			|it = 'La data di completamento del periodo di validità dei prezzi deve essere successiva all''inizio del periodo. 
			|Documenti non registrati.';
			|pl = 'Data zakończenie terminu ważności cen powinna być większa niż początek okresu.
			|Dokumenty nie zostały zapisane.';
			|tr = 'Fiyat geçerlilik döneminin sona erme tarihi, dönemin başlangıcından daha büyük olmalıdır.
			|Belgeler kaydedilmedi.'");
		CommonClient.MessageToUser(MessageText,,"PriceValidityDate1");
		Return;
	EndIf; 
	
	If UsePriceManagementSystem25 Then
		Cancel = False;
		SettingPricesClientServer.CheckFillingInVATRateOfPriceTree(ThisObject, Cancel, True);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	Data = RecordPriceChangesOnServer(Result.Comment, Result.PriceApplicationOption);
	
	If Data <> Undefined Then
		
		For Each TSRow In Data Do
			NotificationText1 = NStr("vi = 'Đã tạo mới chứng từ';
									|ru = 'Создан новый документ';
									|en = 'New document is created'; fa = 'سند جدید ایجاد شد';
									|it = 'Il nuovo documento è stato creato';
									|pl = 'Utwórz nowy dokument';
									|tr = 'Yeni belge oluşturuldu'");
			NotificationParameters = Undefined;
			Notify("Write_PriceSetup", NotificationParameters, TSRow.PriceSetup);
			ShowUserNotification(NotificationText1,
				GetURL(TSRow.PriceSetup),
				String(TSRow.PriceSetup),
				PictureLib.Information32);
			
			If ValueIsFilled(TSRow.PriceApproval) Then
				NotificationText1 = NStr("vi = 'Đã khởi động quy trình nghiệp vụ thống nhất đơn giá mới';
										|ru = 'Запущен бизнес-процесс согласования новых цен';
										|en = 'Business process of new price approval is started'; fa = 'Business process of new price approval is started';
										|it = 'Avviato il processo della definizione dei nuovi prezzi';
										|pl = 'Został uruchomiony proces biznesowy uzgodnienia nowych cen';
										|tr = 'Yeni fiyatların mutabakatı için bir iş süreci başlatıldı'");
				NotificationParameters = Undefined;
				Notify("Write_PriceApproval", NotificationParameters, TSRow.PriceApproval);
				ShowUserNotification(NotificationText1,
					GetURL(TSRow.PriceApproval),
					String(TSRow.PriceApproval),
					PictureLib.Information32);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If IsOpen() And AllowClose Then
		Close(Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessingIssueResultBeforeClosing(Result, Var_Parameters) Export
	
	QuestionIsDisplayed = False;
	
	If Result = "CloseWithoutSaving" Then
		
		CancelPriceChangesOnServer(True);
		OpenWaitingWindowApplySettingsInBackground();
		AllowClose = True;
		If IsOpen() Then
			Close(Undefined);
		EndIf;
		
	EndIf;
	
	If Result = "WriteAndClose" Then
		
		RecordPriceChanges();	
		AllowClose = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfEditColumns(Form, UseTheEditMode)

	For Each CurItem In Form.Items.PriceTree.ChildItems Do
		If StrFind(CurItem.Name, "GroupPrices" + "PriceKind") Then

			For Each NestedItem In CurItem.ChildItems Do
				If StrFind(NestedItem.Name, "TechnicalGroup") Then
					For Each NestedElementByTechnicalGroup In NestedItem.ChildItems Do
						If StrFind(NestedElementByTechnicalGroup.Name, "OldPrice") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowEffectivePrices;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "Formula") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowFormulas;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "ChangePercentage") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowMarkupPercent;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "AmountOfChange") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowPriceChange;
						EndIf;
						If StrFind(NestedElementByTechnicalGroup.Name, "Currency") Then
							NestedElementByTechnicalGroup.Visible = Form.ShowCurrency;
						EndIf;
					EndDo;
				EndIf;
				
				If StrFind(NestedItem.Name, "PackingGroup") Then
					NestedItem.Visible = Form.ShowUnitsOfMeasurement;
				EndIf;
				
				If StrFind(NestedItem.Name, "VATRate") Then
					NestedItem.Visible = Form.ShowVATRate;
				EndIf;

			EndDo;
		EndIf;
	EndDo;

	If Form.UsePriceManagementSystem25 Then
		Form.Items.PriceTreeCharacteristic.Visible = False;
		Form.Items.FillInVATRateView.Visible = Form.ShowVATRate;
		Form.Items.FillInVATRateEdit.Visible = Form.ShowVATRate;
	Else
		Form.Items.PriceTreeCharacteristic.Visible = True;
	EndIf;

	If UseTheEditMode Then
		Form.Items.CommandBarPages.CurrentPage = Form.Items.CommandBarPages.ChildItems.EditingPage;
		Form.Items.ToCompleteThePriceChange.DefaultButton = True;
	Else
		Form.Items.CommandBarPages.CurrentPage = Form.Items.CommandBarPages.ChildItems.ViewPage;
		Form.Items.Generate.DefaultButton = True;
		Form.Modified = False;
	EndIf;

	Form.UseTheEditMode = UseTheEditMode;

EndProcedure

&AtServer
Procedure ConfigurePriceKeyColumns()

	If (UseOneColumnForThePriceKey) Then
		Items.PriceTreeGroupItem.Group = ColumnsGroup.InCell;
	Else
		Items.PriceTreeGroupItem.Group = ColumnsGroup.Horizontal;
	EndIf;
	
EndProcedure

&AtServer
Function LoadFromExcelOnServer(Parameter)
	
	Return SettingPricesServer.ImportFromExcel(ThisObject, Parameter.TypesOfPrices, Parameter.Goods);
	
EndFunction

&AtServer
Procedure CalculatePricesOnServer(CalculationParameters)
	SettingPricesServer.CalculatePrices(ThisObject, CalculationParameters);
EndProcedure

&AtServer
Function AddressOfPriceListSettingsInTemporaryStorage()
	
	ComposerSettings = SettingsComposerFilter.GetSettings();
	ColumnComposerSettings = SettingsBuilderColumnSelection.GetSettings();
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ComposerSettings", ComposerSettings);
	StructureOfData.Insert("ColumnComposerSettings", ColumnComposerSettings);
	StructureOfData.Insert("AddressOfTheStorageOfLayoutSchemeParametersByPriceType", AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
	StructureOfData.Insert("StorageAddressDataLayoutSettings", StorageAddressDataLayoutSettings);
	StructureOfData.Insert("SelectedPrices", SelectedPrices.Unload());
	StructureOfData.Insert("Date", Date);
	StructureOfData.Insert("FilterParametersTable", FilterParametersTable.Unload());
	StructureOfData.Insert("SettingKind", SettingKind);
	StructureOfData.Insert("NavigationOption", NavigationOption);
	StructureOfData.Insert("ProductKind", ProductKind);
	StructureOfData.Insert("GroupingOption", GroupingOption);
	StructureOfData.Insert("OptionForSettingThePrice", OptionForSettingThePrice);
	
	Return PutToTempStorage(StructureOfData, UUID);
	
EndFunction

&AtClient
Procedure OpenPriceListSettingsForm(SelectionOnly = False, GoodsWithSimilarProperties = Undefined)
	
	AddressInTempStorage = AddressOfPriceListSettingsInTemporaryStorage();
	
	FormParameters = New Structure;
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("PriceListSettings", AddressInTempStorage);
	FormParameters.Insert("Date", Date);
	FormParameters.Insert("SelectionOnly", SelectionOnly);
	FormParameters.Insert("GoodsWithSimilarProperties", GoodsWithSimilarProperties);
	
	OpenForm("DataProcessor.PriceList.Form.FormSettings", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure ReformatPriceTable(RecalculatePrices_)
	SettingPricesServer.ReformatPriceTable(ThisObject, RecalculatePrices_);
EndProcedure

&AtServer
Procedure UpdateOldProductPricesOnServer()
	SettingPricesServer.UpdateOldProductPrices(ThisObject);
EndProcedure

&AtServer
Function DataForPrintingPriceTags()
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",       Undefined);
	StructureOfActions.Insert("FillInPriceView",     ?(SelectedPrices.Count() = 1, SelectedPrices[0].Ref, Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", False);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	DataCache = SettingPricesServer.InitializeDataCacheStructure();

	GoodsTable = SettingPricesServer.GoodsTable(ThisObject, DataCache, New Structure("OnlyChangedItems, ByChangesPerDay", True, True));
	If UsePriceManagementSystem25 Then
		GoodsTable = SettingPricesServer.AddProductsToTable(GoodsTable);
	EndIf;

	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", GoodsTable);
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

&AtServer
Function LabelPrintingData()

	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",       Undefined);
	StructureOfActions.Insert("FillInPriceView",     ?(SelectedPrices.Count() = 1, SelectedPrices[0].Ref, Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", False);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForStockBalances");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	GoodsTable = SettingPricesServer.GoodsTable(ThisObject, DataCache, New Structure("OnlyChangedItems, ByChangesPerDay", True, True));
	
	If UsePriceManagementSystem25 Then
		GoodsTable = SettingPricesServer.AddProductsToTable(GoodsTable);
	EndIf;

	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", GoodsTable);
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

&AtClient
Procedure SetListsForSelection(SelectionLists_, TSRow)
	
	SelectionLists_.ItemList.Add(TSRow.Products);
	If ValueIsFilled(TSRow.PricingVariant) Then
		If SelectionLists_.ListOfTSOCharacteristics.FindByValue(TSRow.PricingVariant) = Undefined Then
			SelectionLists_.ListOfTSOCharacteristics.Add(TSRow.PricingVariant);
		EndIf;
	EndIf;
	
	If ValueIsFilled(TSRow.PricingBatch) Then
		If SelectionLists_.ListOfTSOSeries.FindByValue(TSRow.PricingBatch) = Undefined Then
			SelectionLists_.ListOfTSOSeries.Add(TSRow.PricingBatch);
		EndIf;
	EndIf;
	
	If ValueIsFilled(TSRow.PricingPackage) Then
		If SelectionLists_.ListOfTSOSeries.FindByValue(TSRow.PricingPackage) = Undefined Then
			SelectionLists_.ListOfTSOPackages.Add(TSRow.PricingPackage);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure GoThroughHierarchy(SelectionLists_, TSStrings)
	
	For Each TSRow In TSStrings Do
		If TSRow.ThisIsHierarchy Then
			GoThroughHierarchy(SelectionLists_, TSRow.GetItems());
		Else
			SetListsForSelection(SelectionLists_, TSRow);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure MarkModifiedFormulasServer(PricesKind = Undefined)
	SettingPricesServer.MarkModifiedFormulas(ThisObject,,PricesKind);
EndProcedure

&AtClient
Procedure UpdateInformationLine()
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Item = Items.PriceTree;
	If Items.PriceTree.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");
	If SubstringPosition <> 0 Then
		ColumnName = Right(Item.CurrentItem.Name, StrLen(Item.CurrentItem.Name) - SubstringPosition + 1);
		
		If TheCurrentNameOfTheColumn <> ColumnName Or CurrentRowID <> Items.PriceTree.CurrentRow Then
			
			PriceKind = GetPriceViewByColumnName(ColumnName);
			TheCurrentNameOfTheColumn 			= ColumnName;
			CurrentRowID 	= Items.PriceTree.CurrentRow;
			
			If PriceKind <> Undefined Then
				IDOfTheCurrentPriceType = PriceKind.GetID();
				If Items.PriceTree.SelectedRows.Count() > 1 Then
					ArrayOfCurrencies = GetArrayOfUsedCurrencies("Currency" + ColumnName, True);
					InformationBar = GetInformationStringForPriceType(Items,PriceKind.Ref, ArrayOfCurrencies, ColumnName); 
				Else

					ThereIsPriceSetByFutureDate = ThereIsPriceSetByFutureDate(PriceKind.Ref,CurrentData.Products, CurrentData.Characteristic);
					
					InformationBar = SettingPricesClient.GetInformationStringForCell(
										Items,
										SelectedPrices,
										ValidPriceDate,
										CurrentDate,
										UseItemVariants,
										ThereIsPriceSetByFutureDate,
										PriceKind);	
									EndIf;
									
				ChangeValueString	= GetFormulaOfPriceType(ColumnName, PriceKind);
				
			Else
				TheCurrentNameOfTheColumn 			= "";
				IDOfTheCurrentPriceType= 0;
				CurrentRowID 	= 0;
				InformationBar 		= "";
			EndIf;
		EndIf;
	Else
		If CurrentRowID <> Items.PriceTree.CurrentRow Then 
			TheCurrentNameOfTheColumn 			= "";
			IDOfTheCurrentPriceType= 0;
			CurrentRowID 	= Items.PriceTree.CurrentRow;
			InformationBar 		= "";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDataOnChangeHistory()

	ClearHistoryInformation();

	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	Item = Items.PriceTree;
	SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");
	If SubstringPosition <> 0 Then
		ColumnName = Right(Item.CurrentItem.Name, StrLen(Item.CurrentItem.Name) - SubstringPosition + 1);
		PriceKind = GetPriceViewByColumnName(ColumnName);
	
		CurPriceDate = GetCurPriceDate();
		
		FillParameters = New Structure;
		FillParameters.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
		FillParameters.Insert("Products", CurrentData.Products);
		FillParameters.Insert("Characteristic", CurrentData.Characteristic);
		FillParameters.Insert("PricingVariant", CurrentData.PricingVariant);
		FillParameters.Insert("PricingBatch", CurrentData.PricingBatch);
		FillParameters.Insert("UnitOfMeasure", CurrentData.UnitOfMeasure);
		If CurrentData.PricingPackage = CurrentData.UnitOfMeasure Then
			FillParameters.Insert("PricingPackage", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		Else
			FillParameters.Insert("PricingPackage", CurrentData.PricingPackage);
		EndIf;
		
		Filter = GetPriceOnDate(CurPriceDate, PriceKind.Ref, FillParameters);
		
		FillParameters.Insert("PriceKind",PriceKind.Ref);
		FillParameters.Insert("CurrentData",CurrentData);
		FillParameters.Insert("ColumnName",ColumnName);
		FillParameters.Insert("Filter",Filter);
		
		FillInPriceChangeHistoryGroup(FillParameters);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetInformationHistoryLines(ParametersStructure)
	
	PriceHistory = GetPriceHistoryData(ParametersStructure);
	If PriceHistory.Count() =0 Then
		EmptyHistory = True;
	Else
		EmptyHistory = False;
	EndIf;
	
	FormattedHistoryString 				= "";
	FormattedSpeakerString 				= "";
	ArrayOfFormattedStrings 					= New Array;
	ArrayOfFormattedDynamicsStrings 			= New Array;
	ArrayOfFormattedRowsOfTrendIcons 	= New Array;
	ArrayOfFormattedStringsAtBeginningOfLine 		= New Array;
	ArrayOfFormattedStringsByStock 			= New Array;
	
	PriceHistory.Columns.Add("ThisIsCurPrice", New TypeDescription("Boolean"));
	PriceHistory.Columns.Add("PriceChanged_", New TypeDescription("Boolean"));
	
	If ParametersStructure.OldPrice <> ParametersStructure.NewPrice Then 
		RowNew_ = PriceHistory.Add();
		RowNew_.Price = ParametersStructure.NewPrice;
		RowNew_.Period = ParametersStructure.Date;
		RowNew_.Currency = ParametersStructure.Currency;
		RowNew_.ThisIsCurPrice = True;
		RowNew_.PriceChanged_ = ParametersStructure.PriceChanged_;
	Else
		If ParametersStructure.Filter <> Undefined Then
			CurPriceRow = PriceHistory.FindRows(ParametersStructure.Filter);
			If CurPriceRow.Count()>0 Then
				CurPriceRow[0].ThisIsCurPrice = True;
				CurPriceRow[0].PriceChanged_ = ParametersStructure.PriceChanged_;
			EndIf;
		EndIf;
	EndIf;
	
	PriceHistory.Sort("Period Asc");	
	
	For Indus = 0 To PriceHistory.Count()-1 Do
		RowParameters = New Structure;
		Page1 = PriceHistory.Get(Indus);
		If Indus=0 And PriceHistory.Count()<6 Then
			RowParameters.Insert("Price",Page1.Price);
			RowParameters.Insert("Period",Page1.Period);
			RowParameters.Insert("Currency",Page1.Currency);
			RowParameters.Insert("ThisIsCurPrice",Page1.ThisIsCurPrice);	
			RowParameters.Insert("PriceChanged_",Page1.PriceChanged_);	
			RowParameters.Insert("IsWebClient",ParametersStructure.IsWebClient);
		ElsIf Indus>0 Then			
			Page1 = PriceHistory.Get(Indus);
			PreviousRow = PriceHistory.Get(Indus-1);
			RowParameters.Insert("Price",Page1.Price);
			RowParameters.Insert("Period",Page1.Period);
			RowParameters.Insert("Currency",Page1.Currency);
			RowParameters.Insert("ThisIsCurPrice",Page1.ThisIsCurPrice);
			RowParameters.Insert("PriceChanged_",Page1.PriceChanged_);
			RowParameters.Insert("MarketingActivity",Page1.MarketingActivity);
			RowParameters.Insert("PreviousPrice",PreviousRow.Price);
			RowParameters.Insert("Previous_Period",PreviousRow.Period);
			RowParameters.Insert("PreviousCurrency",PreviousRow.Currency);
			RowParameters.Insert("IsWebClient",ParametersStructure.IsWebClient);
		EndIf;
		
		If RowParameters.Count()>0 Then
						
			LinesOfHistory = GetHistoryInformationLine(RowParameters);

			FormattedHistoryString = LinesOfHistory.FormattedHistoryString;
			FormattedSpeakerString = LinesOfHistory.FormattedSpeakerString;
			FormattedStringTrendIcon = LinesOfHistory.FormattedStringTrendIcon;
			FormattedStringStartOfString = LinesOfHistory.FormattedStringStartOfString;
			FormattedStringByStock = LinesOfHistory.FormattedStringByStock;
			
			If Indus<>PriceHistory.Count()-1 Then
				FormattedHistoryString = New FormattedString(FormattedHistoryString,New FormattedString("
				|
				|"));
				FormattedSpeakerString = New FormattedString(FormattedSpeakerString,New FormattedString("
				|
				|"));
				FormattedStringTrendIcon = New FormattedString(FormattedStringTrendIcon,New FormattedString("
				|
				|"));
				FormattedStringStartOfString = New FormattedString(FormattedStringStartOfString,New FormattedString("
				|
				|"));
				FormattedStringByStock = New FormattedString(FormattedStringByStock,New FormattedString("
				|
				|"));
				
			EndIf;
			
			ArrayOfFormattedStrings.Add(FormattedHistoryString);
			ArrayOfFormattedDynamicsStrings.Add(FormattedSpeakerString);
			ArrayOfFormattedRowsOfTrendIcons.Add(FormattedStringTrendIcon);
			ArrayOfFormattedStringsAtBeginningOfLine.Add(FormattedStringStartOfString);
			ArrayOfFormattedStringsByStock.Add(FormattedStringByStock);
		EndIf;
	EndDo;
	
	StructureOfArraysOfStrings = New Structure();
	StructureOfArraysOfStrings.Insert("ArrayOfFormattedStrings", ArrayOfFormattedStrings);
	StructureOfArraysOfStrings.Insert("ArrayOfFormattedDynamicsStrings", ArrayOfFormattedDynamicsStrings);
	StructureOfArraysOfStrings.Insert("ArrayOfFormattedRowsOfTrendIcons", ArrayOfFormattedRowsOfTrendIcons);
	StructureOfArraysOfStrings.Insert("ArrayOfFormattedStringsAtBeginningOfLine", ArrayOfFormattedStringsAtBeginningOfLine);
	StructureOfArraysOfStrings.Insert("ArrayOfFormattedStringsByStock", ArrayOfFormattedStringsByStock); 
	StructureOfArraysOfStrings.Insert("EmptyHistory", EmptyHistory);
	
	Return StructureOfArraysOfStrings;
	
EndFunction

#Region Other

&AtServer
Function PutInfluencingKindsOfPricesInStorage(InfluencingPrices)
//	 attention upload only selected and not all prices
	Tree = ProcessingOfFormulas.GetEmptyOperandTree();

	For Each Item In InfluencingPrices Do	
		FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("Ref", Item.Value));
		If FoundTypesOfPrices.Count() = 1 Then
			LineTypesOfPrice = FoundTypesOfPrices[0];
			OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
			OperandString_.Id = LineTypesOfPrice.Id;
			OperandString_.Presentation = String(LineTypesOfPrice.Ref);
			OperandString_.DeletionMark = LineTypesOfPrice.DeletionMark;
			OperandString_.ValueType = New TypeDescription("Number");
		EndIf;
	EndDo;
	
	AddressInStorage = PutToTempStorage(Tree, UUID);
	
	Return AddressInStorage;
	
EndFunction

&AtClient
Function GetParametersOfPriceEditingForm_1(Formula)
	
	SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");	
	If SubstringPosition <> 0 Then
		CurColumnName = Right(Items.PriceTree.CurrentItem.Name, StrLen(Items.PriceTree.CurrentItem.Name) - SubstringPosition + 1);			
	EndIf;
	
	PriceKind = GetPriceViewByColumnName(CurColumnName);
	
	If PriceKind <> Undefined Then
		InfluencingPrices = PriceKind.InfluencingPrices;
	Else
		InfluencingPrices = New ValueList; 
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Formula", Formula);
	ReturnStructure.Insert("OperandsTree", PutInfluencingKindsOfPricesInStorage(InfluencingPrices));
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá được phép';
												|ru = 'Доступные виды цен';
												|en = 'Available price types'; fa = 'Available price types';
												|it = 'Tipi di prezzi disponibili';
												|pl = 'Dostępne rodzaje cen';
												|tr = 'Mevcut fiyat türleri'"));
	ReturnStructure.Insert("Operators", OperatorsTreeStorageAddress);
	ReturnStructure.Insert("ResultType", New TypeDescription("Number"));
	ReturnStructure.Insert("ThisIsPriceCalculation", True);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Function GetParametersOfPriceEditingForm(TagName)
	
	CurColumnName  = StrReplace(TagName, "PriceTree", "");
	PriceViewFormula	= GetFormulaOfPriceType(TagName);
	
	PriceKind = GetPriceViewByColumnName(CurColumnName);
	
	If PriceKind <> Undefined Then
		InfluencingPrices = PriceKind.InfluencingPrices;
	Else
		InfluencingPrices = New ValueList; 
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("NameOfReturnElement", CurColumnName);
	ReturnStructure.Insert("Formula", 	PriceViewFormula);
	ReturnStructure.Insert("OperandsTree", PutInfluencingKindsOfPricesInStorage(InfluencingPrices));
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá được phép';
												|ru = 'Доступные виды цен';
												|en = 'Available price types'; fa = 'Available price types';
												|it = 'Tipi di prezzi disponibili';
												|pl = 'Dostępne rodzaje cen';
												|tr = 'Mevcut fiyat türleri'"));
	ReturnStructure.Insert("Operators", OperatorsTreeStorageAddress);
	ReturnStructure.Insert("ResultType", New TypeDescription("Number"));
	ReturnStructure.Insert("ThisIsPriceCalculation", True);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Function GetFormulaOfPriceType(TagName, PriceKind = Undefined)

	PriceViewFormula = "";	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Then
		Return "";
	EndIf;

	SubstringPosition = StrFind(TagName, "PriceKind");
	ColumnName = Right(TagName, StrLen(TagName) - SubstringPosition + 1);
	
	PriceViewFormula = CurrentData["Formula" + ColumnName];
	StructurePriceGroup = New Structure("PriceGroup", CurrentData.PriceGroup);
	
	FormulasAreUsed = True;
	
	If Not ValueIsFilled(PriceViewFormula) Then
		
		FormulasAreUsed = False;

		If PriceKind = Undefined Then
			
			PriceKind = GetPriceViewByColumnName(TagName);
			
		EndIf;
		
		If Not PriceKind = Undefined Then
			
			
			If PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") 
				Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
				
				FormulasAreUsed = True;
			
				PriceViewFormula = PriceKind.Formula;
				PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
				
				If PriceGroupsOfAlgorithms.Count() > 0 Then
					PriceViewFormula = PriceGroupsOfAlgorithms[0].Formula;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;

	Items.ChangeValueString.ReadOnly = Not FormulasAreUsed;
	
	If FormulasAreUsed Then
		Items.ChangeValueString.InputHint = NStr("vi = '<công thức theo dạng giá>';
												|ru = '<формула по виду цен>';
												|en = '<formula by price type>'; fa = '<formula by price type>';
												|it = '<формула по виду цен>';
												|pl = '<formula by price type>';
												|tr = '<fiyat türüne göre formül>'");
	Else
		Items.ChangeValueString.InputHint = NStr("vi = '<không sử dụng công thức>';
												|ru = '<формулы не используются>';
												|en = '<formulas are not used>'; fa = '<formulas are not used>';
												|it = '<Le formule non sono utilizzate>';
												|pl = '<formuły nie są używane>';
												|tr = '<formüller kullanılmamaktadır>'");
	EndIf;
	
	Return PriceViewFormula;
EndFunction

&AtClient
Function GetPriceViewByColumnName(TagName)

	PriceKind = Undefined;	
	
	SubstringPosition = StrFind(TagName, "PriceKind");
	ColumnName = Right(TagName, StrLen(TagName) - SubstringPosition + 1);
	If TheCurrentNameOfTheColumn = ColumnName And IDOfTheCurrentPriceType <> 0 Then
		
		PriceKind = SelectedPrices.FindByID(IDOfTheCurrentPriceType);
	
	Else	
		
		FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
		If FoundTypesOfPrices.Count() = 1 Then
			PriceKind = FoundTypesOfPrices[0];
		EndIf;
	
	EndIf;
	
	Return PriceKind;
	
EndFunction

// Sets the flag for fixing the "Nomenclature" and "Characteristic" columns on the left
//
// Parameters:
// NewValue - Boolean
//
&AtServer
Procedure FixTheItemColumn(NewValue)
	
	If NewValue = Undefined Then
		NewValue = True;
	EndIf;
	
	FixTheItemColumn = NewValue;
	
	Items.PriceTreeGroupItem.FixingInTable 		= ?(FixTheItemColumn,FixingInTable.Left,FixingInTable.None);
	
EndProcedure

&AtServer
Procedure ChangePricesToPercentageOnServer(CalculationParameters)
	SettingPricesServer.ChangePricesByPercentage_2(ThisObject, CalculationParameters);
EndProcedure

&AtServer
Procedure ChangePricesOnServer(CalculationParameters)
	SettingPricesServer.ChangePrices(ThisObject, CalculationParameters);
EndProcedure

// Sets the automatic price recalculation flag
//
// Parameters:
// NewValue - Boolean
//
&AtClient
Procedure SetCountAutomaticallyOnClient(NewValue)
	
	CalculateAutomatically = NewValue;
	
EndProcedure

// Returns the structure of parameters required for calculating prices
//
// Parameters:
// Loading old prices-Boolean-Indicates the need to load old values of manual prices
// Rounding the unit price-Boolean-Indicates the need for rounding manual prices.
//
// Returns:
// Structure
// Structure Keys:
// Loading the Old Price - Boolean
// Rounding up the individual price is Boolean
// The type of price is an array.
//
&AtClient
Function ParametersForOpeningCalculationParametersSelectionForm(FillParameters)
	
	TypesOfPrices = New Array();
	
	For Each LineTypesOfPrice In SelectedPrices Do
		If Not (LineTypesOfPrice.Selected_5 And LineTypesOfPrice.Edit) Then
			Continue;
		EndIf;
		If FillParameters.CalculationOfInformationSecurity 
			And (LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseData")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataOnReceipt")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost")) Then
					
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		ElsIf FillParameters.CalculationByFormulas 
				And (LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup")
				Or LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes")) Then
					
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		ElsIf FillParameters.ImportFromYandexMarket 
				And LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.ImportedFromYandexMarket") Then
					
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		ElsIf FillParameters.LoadingFromOzon 
				And LineTypesOfPrice.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.ImportedFromOzon") Then
				
				TypesOfPrices.Add(LineTypesOfPrice.Ref);
				
		Else
			TypesOfPrices.Add(LineTypesOfPrice.Ref);
		EndIf;
	EndDo;
	
	OnlySelectedItems = Items.PriceTree.SelectedRows.Count() > 1;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ImportOldPrices", FillParameters.ImportOldPrices);
	ReturnStructure.Insert("RoundingUpManualPrices", FillParameters.RoundingUpManualPrices);
	ReturnStructure.Insert("ManualPriceViews", TypesOfPrices);
	ReturnStructure.Insert("DocumentDate", Date);
	ReturnStructure.Insert("OnlySelectedItems", OnlySelectedItems);
	ReturnStructure.Insert("AllKindsOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject, True));
	ReturnStructure.Insert("OperatorsTreeStorageAddress", OperatorsTreeStorageAddress);
	If FillParameters.Property("CalculationByFormulas") Then
		ReturnStructure.Insert("CalculationByFormulas", FillParameters.CalculationByFormulas);
	EndIf;
	ReturnStructure.Insert("OnlyEmpty",False);
	If FillParameters.Property("ArrayOfCurrenciesByPriceType") Then
		ReturnStructure.Insert("ArrayOfCurrenciesByPriceType", FillParameters.ArrayOfCurrenciesByPriceType);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function AddressInTemporaryPrintDataStore()
	
	DataForPrint = New Structure;
	DataForPrint.Insert("TypesOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	DataForPrint.Insert("Goods", SettingPricesServer.GoodsTable(ThisObject));
	DataForPrint.Insert("UsePriceManagementSystem25", UsePriceManagementSystem25);
	
	If Not ValueIsFilled(ValidPriceDate) Then
		DataForPrint.Insert("ValidPriceDate", BegOfDay(Date) - 1);
	Else
		DataForPrint.Insert("ValidPriceDate", ValidPriceDate);
	EndIf;
	
	Return PutToTempStorage(DataForPrint, UUID);
	
EndFunction

&AtServer
Procedure CalculatePricesByRowIDOnServer(RowID, ModifiedField)
	If UsePriceManagementSystem25 Then
		SettingPricesServer.CalculatePricesByRowId2_5(ThisObject, RowID,,ModifiedField);
	Else	
		SettingPricesServer.CalculatePricesByRowId(ThisObject, RowID,,ModifiedField);
	EndIf;	
EndProcedure

&AtServerNoContext
Function CoefficientsOfProductPackages(ArrayOfProductPackagingStructures)
	
	Return SettingPricesServer.ComplianceOfCoefficientsOfCollectionOfPackagesOfProductRange(ArrayOfProductPackagingStructures);
	
EndFunction

&AtServer
Procedure ClearSavedDocumentsAndApplySettings(Val ValueSelected)
	
	SettingPricesServer.ClearSavedDocuments(SavedDocuments, UUID);
	
	ApplySettings(ValueSelected);
	
EndProcedure

&AtServerNoContext
Function GetArrayOfPreviouslySetPriceTypesByProductType(ParametersOfPriceTypes)
	
	Return SettingPricesServer.GetArrayOfPreviouslySetPriceTypesByProductType(ParametersOfPriceTypes);
		
EndFunction

&AtClientAtServerNoContext
Function TitleText(Form)

	If Form.SetTemporaryPrices Then
		TitleText = NStr("vi = 'Bảng giá từ %1 đến %2';
						|ru = 'Прайс-лист с %1 по %2';
						|en = 'Price list from %1 to %2'; fa = 'Price list from %1 to %2';
						|it = 'Listino prezzi da %1 a %2';
						|pl = 'Cennik od %1 do %2';
						|tr = '%1 ile %2 arası fiyat listesi'");
	Else
		TitleText = NStr("vi = 'Bảng giá tại ngày %1';
						|ru = 'Прайс-лист на %1';
						|en = 'Price list as of %1'; fa = 'Price list as of %1';
						|it = 'Listino dei prezzi per %1';
						|pl = 'Cennik na %1';
						|tr = '%1 tarihli fiyat listesi'");
	EndIf;
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		TitleText,Format(Form.Date,"DLF=DD"),Format(Form.EndDateOfThePricePeriod, "DLF=DD"));
	
	Return TitleText;

EndFunction // The text of the subtitle()


#Region TimeConsumingOperations
&AtClient
Procedure OpenWaitingWindowApplySettingsInBackground()
	
	If ValueIsFilled(JobID) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = True;
		IdleParameters.OutputMessages     = True;
		IdleParameters.MessageText     	= NStr("vi = 'Đang điền đơn giá của bảng giá';
													|ru = 'Идет заполнение цен прайс-листа';
													|en = 'Populating price list prices'; fa = 'Populating price list prices';
													|it = 'Compilazione del listino prezzi in corso';
													|pl = 'Trwa wypełnienie cen cennika';
													|tr = 'Fiyat listesi fiyatları dolduruluyor'");
		
		CallbackOnCompletion = New CallbackDescription("ApplySettingsInBackground__OnClient", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfCalculatingALongOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPriceCalculationWaitingWindowInBackground(Val ProcedureName)
	
	If ValueIsFilled(JobID) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = True;
		IdleParameters.OutputMessages     = True;
		IdleParameters.MessageText     	= NStr("vi = 'Đang tính đơn giá của bảng giá';
													|ru = 'Идет расчет цен прайс-листа';
													|en = 'Calculating price list prices'; fa = 'Calculating price list prices';
													|it = 'Calcolo prezzi del listino prezzi in corso';
													|pl = 'Trwa obliczenie cen cennika';
													|tr = 'Fiyat listesi fiyatları hesaplanıyor'");
		
		CallbackOnCompletion = New CallbackDescription(ProcedureName, ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfCalculatingALongOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplySettingsInBackground__OnClient(BackgroundJob, AdditionalParameters) Export
	
	ResultOfCalculatingALongOperation = BackgroundJob;
	
	If Not ResultOfCalculatingALongOperation = Undefined Then
		If ResultOfCalculatingALongOperation.Status = "Completed2" Then
			ApplySettingsInBackgroundCompletion();
		ElsIf ResultOfCalculatingALongOperation.Status = "Error" Then
			CommonClientServer.MessageToUser(ResultOfCalculatingALongOperation.BriefErrorDescription);
		EndIf;
	EndIf;
	
	ResultOfCalculatingALongOperation 	= Undefined;
	JobID				= Undefined;

EndProcedure

&AtServer
Procedure ApplySettingsInBackgroundCompletion()
	
	BackgroundJobExecutionResult  = GetFromTempStorage(AddressOfTheTaskResultStorage);
	NumberOfRowsInThePriceTree			= BackgroundJobExecutionResult.ShapeStructure.NumberOfRowsInThePriceTree;
	Tree = BackgroundJobExecutionResult.ShapeStructure.PriceTree;
	AddSelectionBasedOnPriceSettingOption(Tree);
	ValueToFormAttribute(Tree, "PriceTree");
	SettingPricesServer.MarkModifiedFormulas(ThisObject, Tree);
	
EndProcedure

&AtClient
Procedure ChangePricesOnClientEndMain(BackgroundJob, AdditionalParameters = Undefined) Export
	
	ResultOfCalculatingALongOperation = BackgroundJob;
	
	If Not ResultOfCalculatingALongOperation = Undefined Then
		If ResultOfCalculatingALongOperation.Status = "Completed2" Then
			// let's find how many elements there are in total
			CurrentRowID = Items.PriceTree.CurrentRow;
			ChangePricesOnServerEndTotal();
			If CurrentRowID<>Undefined Then
				Items.PriceTree.CurrentRow = CurrentRowID + NumberOfRowsInThePriceTree;
			EndIf;
			ChangePricesOnClientEndingSnippet();
		ElsIf ResultOfCalculatingALongOperation.Status = "Error" Then
			CommonClientServer.MessageToUser(ResultOfCalculatingALongOperation.BriefErrorDescription);
		EndIf;
	EndIf;
	
	ResultOfCalculatingALongOperation 	= Undefined;	
	JobID				= Undefined;

EndProcedure

&AtClient
Procedure ChangePricesOnClientEndingSnippet()
	
	UpdateInformationLine();

EndProcedure

&AtServer
Procedure ChangePricesOnServerEndTotal()
	
	BackgroundJobExecutionResult = GetFromTempStorage(AddressOfTheTaskResultStorage);
	Tree = BackgroundJobExecutionResult.ShapeStructure.PriceTree;
	ValueToFormAttribute(Tree, "PriceTree");
	Modified = BackgroundJobExecutionResult.ShapeStructure.Modified;
	SettingPricesServer.MarkModifiedFormulas(ThisObject, Tree);
	
EndProcedure

&AtClient
Procedure LimitPriceSettingToAPeriod(Command)
	Items.LimitPriceSettingToAPeriod.Check = Not Items.LimitPriceSettingToAPeriod.Check;
EndProcedure

&AtClientAtServerNoContext
Procedure SetQuickEditVisibility(Form)
	Form.Items.QuickEditGroup.Visible	= Form.ShowTheQuickEditPanel;
	
	If Form.OptionToChangeThePrice < 4 Then
		
		Form.Items.ChangeValueNumber.Visible	= True;
		Form.Items.ChangeValueString.Visible= False;
		
	Else
				
		Form.Items.ChangeValueNumber.Visible	= False;
		Form.Items.ChangeValueString.Visible= True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTimePricesWhenChangesOccur(Item)
	SetTemporaryPricesWhenChangingOnServer(ThisObject);
EndProcedure

&AtClientAtServerNoContext
Procedure SetTemporaryPricesWhenChangingOnServer(Form)
	
	Form.Items.PriceValidityPeriodSelectionGroup1.Visible 	= Not Form.SetTemporaryPrices;
	Form.Items.PriceValidityPeriodSelectionGroup2.Visible 	= Form.SetTemporaryPrices;
	Form.Items.MarketingActivity.Visible 			= Form.SetTemporaryPrices;
		
	If Form.SetTemporaryPrices Then
		TitleText = NStr("vi = 'Bảng giá từ %1 đến %2';
						|ru = 'Прайс-лист с %1 по %2';
						|en = 'Price list from %1 to %2'; fa = 'Price list from %1 to %2';
						|it = 'Listino prezzi da %1 a %2';
						|pl = 'Cennik od %1 do %2';
						|tr = '%1 ile %2 arası fiyat listesi'");
	Else
		TitleText = NStr("vi = 'Bảng giá tại ngày %1';
						|ru = 'Прайс-лист на %1';
						|en = 'Price list as of %1'; fa = 'Price list as of %1';
						|it = 'Listino dei prezzi per %1';
						|pl = 'Cennik na %1';
						|tr = '%1 tarihli fiyat listesi'");
	EndIf;

	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		TitleText,Format(Form.Date,"DLF=DD"),Format(Form.EndDateOfThePricePeriod, "DLF=DD"));
	Form.Title = TitleText(Form);			
	
EndProcedure

&AtClient
Procedure FillInInformationLineDifferentCurrencies()
	
	FormattedLineMenuItem = New FormattedString("Change prices",New Font(,,True),,,"LinkChangePrices");
	#If Not WebClient Then
		FormattedLineMenuItem = New FormattedString(New FormattedString(" ",PictureLib.Change," "), FormattedLineMenuItem);
	#Else
		FormattedLineMenuItem = "";
	#EndIf
	FormattedStringWarningText = New FormattedString("Values for ofselected_ vida prices_ specified_1 In several various incurrencies. When_ installation_ prices_ from fast panels editing ('Change to1 stash' And 'Set value') for allofthem specified_ ofcurrencies will isset update to1 count, specified_3 In field editing. For installations_1 various values_ In section_ ofcurrencies for everyone vida prices_ use point menu");
	Items.WarningDecoration.Title = New FormattedString(FormattedStringWarningText,FormattedLineMenuItem);	
	
EndProcedure

&AtClient
Procedure InformationBarURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "LinkToPriceHistory" Then
		
		StandardProcessing = False;
		FillInDataOnChangeHistory();
		Items.TheGroupHistoryOfChangesInThePrice.Enabled = True;
		Items.TheGroupHistoryOfChangesInThePrice.Show();
		AttachIdleHandler("SetGroupAvailability", 5);
		
	ElsIf FormattedStringURL = "LinkDifferentCurrencies" Then
		 
		StandardProcessing = False;
		FillInInformationLineDifferentCurrencies();
		Items.GroupOfWarningsAboutDifferentCurrencies.Enabled = True;
		Items.GroupOfWarningsAboutDifferentCurrencies.Show();
		AttachIdleHandler("SetGroupAvailability", 5);
		
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure WarningDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "LinkChangePrices" Then
		StandardProcessing = False;
		ChangePricesOnClientByCallType(False);	
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SceneryShowTheWholeStoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "LinkWholeStory" Then
		StandardProcessing = False;
		CurrentData = Items.PriceTree.CurrentData;
		SubstringPosition = StrFind(Items.PriceTree.CurrentItem.Name, "PriceKind");
		If SubstringPosition <> 0 Then
			CurColumnName = Right(Items.PriceTree.CurrentItem.Name, StrLen(Items.PriceTree.CurrentItem.Name) - SubstringPosition + 1);
		EndIf;
	
		PriceKind = GetPriceViewByColumnName(CurColumnName);
		
		If CurrentData = Undefined Then
			Return;
		EndIf;	
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Key",           CurrentData.Products);
		FormOpenParameters.Insert("Characteristic", CurrentData.Characteristic);
		If PriceKind <> Undefined Then
			FormOpenParameters.Insert("PriceKind",PriceKind.Ref);
		EndIf;
		OpenForm("Catalog.Products.Form.PricesHistoryOfItemsAndService", FormOpenParameters);
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationPriceHistoryChangesInTheNomenclatureURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "ShowDynamicsLink" Then
		StandardProcessing = False;	
		GenerateReportOnPriceDynamics();
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenWaitingWindowForChangeInPersonalIncomeTaxRateInBackground(Val ProcedureName)
	
	If ValueIsFilled(JobID) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = True;
		IdleParameters.OutputMessages     = True;
		IdleParameters.MessageText     	= NStr("vi = 'Đang thay đổi thuế suất GTGT của bảng giá';
													|ru = 'Идет изменение ставки НДС прайс-листа';
													|en = 'Changing the VAT rate of the price list'; fa = 'Changing the VAT rate of the price list';
													|it = 'Changing the VAT rate of the price list';
													|pl = 'Changing the VAT rate of the price list';
													|tr = 'Fiyat listesindeki KDV oranı değiştiriliyor'");
		
		CallbackOnCompletion = New CallbackDescription(ProcedureName, ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfCalculatingALongOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure DisplayInfluencingPricesOnClient(NewValue)
	
	ShowInfluencingPrices = NewValue;	
	
	ReformatPriceTable = False;
	For Each PriceKind In SelectedPrices Do
		If Not PriceKind.Selected_5 And PriceKind.Influences And Not PriceKind.ProhibitedPriceType Then
			ReformatPriceTable = True;
		EndIf;
	EndDo;
	
	If ReformatPriceTable Then
		ReformatPriceTable(False);
	EndIf;
EndProcedure

&AtClient
Procedure UndoCurrentChanges(Command)
	
	CancelPriceChangesOnServer();
	OpenWaitingWindowApplySettingsInBackground();
	
EndProcedure

&AtClient
Procedure SetGroupAvailability()
	
	If Items.TheGroupHistoryOfChangesInThePrice.Hidden() And Items.GroupOfWarningsAboutDifferentCurrencies.Hidden() Then
		
		Items.TheGroupHistoryOfChangesInThePrice.Enabled = False;
		Items.GroupOfWarningsAboutDifferentCurrencies.Enabled = False;

		DetachIdleHandler("SetGroupAvailability");
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
	
	SettingPricesServer.BuildPriceTree(ThisObject);
	SetVisibilityOfEditColumns(ThisObject, False);
	
EndProcedure

#EndRegion

#Region FillingInVATRates

&AtClient
Procedure SettingsForFillingInVATRatesEnd(Result, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	If Not ValueIsFilled(Result.SelectedTypesOfPrices) Then
		MessageText = NStr("vi = 'Không có dạng giá được chọn để thay đổi.';
							|ru = 'Нет выбранных видов цен для изменения.';
							|en = 'There are no selected price types to change.'; fa = 'There are no selected price types to change.';
							|it = 'There are no selected price types to change.';
							|pl = 'There are no selected price types to change.';
							|tr = 'Değiştirilecek seçili fiyat türü bulunmamaktadır.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	ChangeVATRates(Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ChangeVATRates(Result, AdditionalParameters = Undefined)
	
	CalculationParameters = Result;
		
	SetVisibilityOfEditColumns(ThisObject, True);
	If RunAsynchronously(CalculationParameters) Then
			
		ResultOfCalculatingALongOperation = ChangeVATRatesAtServerInBackground(CalculationParameters);
		JobID						= ResultOfCalculatingALongOperation.JobID;
		AddressOfTheTaskResultStorage 	= ResultOfCalculatingALongOperation.ResultAddress;
		
		If ResultOfCalculatingALongOperation.Status = "Completed2" Then
			ChangePricesOnClientEndMain(ResultOfCalculatingALongOperation);
		Else	
			OpenWaitingWindowForChangeInPersonalIncomeTaxRateInBackground("ChangePricesOnClientEndMain")
		EndIf;
			
	Else
			
		ChangeVATRatesATServer(CalculationParameters);
		ChangePricesOnClientEndingSnippet();
			
	EndIf; 

EndProcedure

&AtServer
Function ChangeVATRatesAtServerInBackground(Val CalculationParameters)
	
	// we prepare the data for launching a long-term filling operation
	// and put the necessary form data into the structure
	ShapeStructure = InitializeFormStructure();
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ShapeStructure"			, ShapeStructure);
	GenerationParameters.Insert("CalculationParameters"		, CalculationParameters);
	
	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.PriceList.ChangeVATRatesATServer",
											JobParameters,
											ExecutionParameters);
	
EndFunction

&AtServer
Procedure ChangeVATRatesATServer(CalculationParameters)
	
	SettingPricesServer.ChangeVATRates(ThisObject, CalculationParameters);
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date1);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDateOfThePricePeriod" Then
		DateOnChange(Items.PriceValidityDate1);
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
