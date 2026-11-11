
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("SettingsStructure") Then
		
		If Parameters.SettingsStructure.Property("EditMode") Then
			Items.FillInDocument.Title = NStr("vi = 'Lưu lại';
												|ru = 'Сохранить';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Sakla'");
			EditMode = True;
		Else
			EditMode = False;
		EndIf;
		
		ThisObject.FilterEmptyLines = True;
		FillInByShortage = False;
		If Parameters.SettingsStructure.Property("FillInByShortage")
			And Parameters.SettingsStructure.FillInByShortage Then
			
			FillInByShortage = True;
			
			Items.FilterEmptyLines.Visible = False;
			Items.FormulaGroup.Visible = False;
			Items.GroupCommentDoNotUseOffset.Visible = False;
			Items.OffsetGroup.Visible = False;
		EndIf;
		
		SettingsStructure = Parameters.SettingsStructure.SettingsStructure;
		FillPropertyValues(ThisObject, Parameters.SettingsStructure,,"AdditionalFields");
		AdditionalFields.Load(Parameters.SettingsStructure.AdditionalFields.Unload());
		FillPropertyValues(ThisObject, SettingsStructure);
		
		DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate("Template");
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
		SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
		FilterOfProductItem.Initialize(SettingsSource);
		FilterOfProductItem.LoadSettings(DataCompositionSchema.DefaultSettings);
		If SettingsStructure.Property("SelectionOfProductsSettings")
			And ValueIsFilled(String(SettingsStructure.SelectionOfProductsSettings.Filter))Then
			FilterOfProductItem.LoadSettings(SettingsStructure.SelectionOfProductsSettings);
			CreatePresentationOfProductSelection();
		EndIf;
		
		If Parameters.SettingsStructure.Filter.Property("FilterItemsType") Then
			FilterElement = DataCompositionClientServer.AddFilter(FilterOfProductItem.Settings,
				"Products.ItemsType",
				Parameters.SettingsStructure.Filter.FilterItemsType,
				DataCompositionComparisonType.Equal);
			FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		
		If Not ValueIsFilled(FormulaPresentation) Then
			FormulaPresentation = PlanningClientServer.TextForSettingNewFormula()
		EndIf;
		
		If PeriodOffset >= 0 Then
		
			OffsetDirection = 1;
			EditedOffset = PeriodOffset;
		
		Else
		
			OffsetDirection = -1;
			EditedOffset = OffsetDirection * PeriodOffset;
		
		EndIf; 
		
	EndIf;
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = PriceManagementSystemServerCall.PriceTypePriceList_();
	EndIf;
	
	If Not ValueIsFilled(PeriodStartPlan) Or Not ValueIsFilled(PeriodEndPlan) Then
		PlanningClientServer.SetStartEndOfPlanPeriod(
			Periodicity,
			PeriodStartPlan,
			PeriodEndPlan,
			CurrentSessionDate(),
			Parameters.SettingsStructure.NumberOfPeriods);
	EndIf;
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
	SetVisibilityOfFormPagesAndAccessibilityOfElements(EditMode, FillInByShortage);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();
	
	If Not (PlanByAmount And PricePopulationOption = "ItemsPrices" And UsePriceType) Then
		AttributesNotToCheck.Add("PriceKind");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OffsetOptionWhenChanging(Item)
	
	WhenOffsetChanges(ThisForm);
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
EndProcedure

&AtClient
Procedure OffsetWhenChanging(Item)
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
EndProcedure

&AtClient
Procedure OffsetDirectionOnChange(Item)
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
EndProcedure

&AtClient
Procedure OptionToFillInPricesAgreementOnChange(Item)
	
	WhenChangingPriceOption(ThisForm);
	
EndProcedure

&AtClient
Procedure OptionForFillingInPricesPartnerOnChange(Item)
	
	WhenChangingPriceOption(ThisForm);
	
EndProcedure

&AtClient
Procedure UsePriceTypeOnChange(Item)
	
	PricePopulationOption = "ItemsPrices";
	WhenChangingUsePriceView(ThisForm);
	
EndProcedure

&AtClient
Procedure FormulaPresentationClick(Item, StandardProcessing)
	
	OpenFormulaEditingDialog();
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DecorationItemSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("DecorationItemSelectionURLProcessingCompletion", ThisForm);
		
	EditingFormParameters = New Structure("SettingsAddress,NameAddressOfTheLayout",
			 SelectionOfProductsSettings(),
			"DataProcessor.GoodsSelectionByPicking.Template");
	
	OpenForm("CommonForm.EditDataCompositionSettings",
		EditingFormParameters,
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure ContentFillingVariantOnChange(Item)
	
	WhenChangingFillOption(ThisForm);
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInDocument(Command)
	
	PeriodOffset = OffsetDirection * EditedOffset;
	
	FillPropertyValues(SettingsStructure, ThisObject);
	SettingsStructure.Insert("SelectionOfProductsSettings", SelectionOfProductsSettings());
	
	EverythingIsFilled = CheckFilling();
	
	If EverythingIsFilled Then
		
		ShouldSaveSettings();
		Close(SettingsStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure WhenOffsetChanges(Form)
	
	If Form.OffsetOption = "CustomValue" Then
		Form.Items.EditedOffset.Enabled = True;
		Form.Items.OffsetDirection.Enabled = True;
	Else
		Form.Items.EditedOffset.Enabled = False;
		Form.Items.OffsetDirection.Enabled = False;
	EndIf;
	
	If Form.OffsetOption = "PreviousPeriod_" Then
		Form.EditedOffset = 1;
		Form.OffsetDirection = -1;
	ElsIf Form.OffsetOption = "CurrentPeriod" Then
		Form.EditedOffset = 0;
		Form.OffsetDirection = -1;
	ElsIf Form.OffsetOption = "PreviousYear" Then
		
		Form.OffsetDirection = -1;
		
		If Form.Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
			Form.EditedOffset = 12;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
			Form.EditedOffset = DayOfYear(EndOfYear(Form.PeriodStartPlan));
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
			Form.EditedOffset = WeekOfYear(EndOfYear(Form.PeriodStartPlan)) - 1;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
			Form.EditedOffset = 36;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
			Form.EditedOffset = 4;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			Form.EditedOffset = 2;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			Form.EditedOffset = 1;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdatePeriodWhenOffsetChanges(Form) 

	Form.PeriodStartOffset = RecalculateBeginningOfPeriod(Form.PeriodStartPlan, Form.Periodicity, Form.EditedOffset, Form.OffsetDirection);
	Form.PeriodEndOffset = RecalculateEndOfPeriod(Form.PeriodEndPlan, Form.Periodicity, Form.EditedOffset, Form.OffsetDirection);
	
	SetPeriodInWords(Form.PeriodOffset, Form.Periodicity, Form.PeriodicityPresentation);
	
	Form.PeriodOffsetView = CreatePeriodPresentation(New Structure("Periodicity, BeginOfPeriod, PeriodEnding", Form.Periodicity, Form.PeriodStartOffset, Form.PeriodEndOffset));
	
EndProcedure

&AtClientAtServerNoContext
Function CreatePeriodPresentation(Parameters) 

	Presentation = "";
	
	BeginOfPeriod 		= Parameters.BeginOfPeriod;
	PeriodEnding	= Parameters.PeriodEnding;
	Periodicity 		= Parameters.Periodicity;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		CurrentSessionDate = CurrentSessionDate();
	#Else 
		CurrentSessionDate = CommonClient.SessionDate();
	#EndIf
	
	PlanningClientServer.SetStartEndOfPlanPeriod(Periodicity, BeginOfPeriod, PeriodEnding, CurrentSessionDate);
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		
		FormatPeriodicityMonth = NStr("vi = 'ДФ=''ММММ гггг''';
										|ru = 'ДФ=''ММММ гггг''';
										|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
										|it = 'DF=''MMMM yyyy''';
										|pl = 'DF=''MMMM yyyy''';
										|tr = 'DF=''MMMM yyyy'''");
		If BegOfMonth(BeginOfPeriod) = BegOfMonth(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, FormatPeriodicityMonth);
		Else
			Presentation = Format(BeginOfPeriod, FormatPeriodicityMonth) + " - " + Format(PeriodEnding, FormatPeriodicityMonth);
		EndIf;
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		FormatPeriodicityDay = "DLF=DD";
		If BegOfDay(BeginOfPeriod) = BegOfDay(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, FormatPeriodicityDay);
		Else
			Presentation = Format(BeginOfPeriod, FormatPeriodicityDay) + " - " + Format(PeriodEnding, FormatPeriodicityDay);
		EndIf;
		
	Else
		
		Presentation = Format(BeginOfPeriod, "DLF=DD") + " - " + Format(PeriodEnding, "DLF=DD");
		
	EndIf;
	
	Return Presentation;

EndFunction

&AtClientAtServerNoContext
Function RecalculateEndOfPeriod(Val BeginOfPeriod, Val Periodicity, Val Offset, Val OffsetDirection)
	
	Offset = OffsetDirection * Offset;
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServerCached.CalculatePeriodEndDate(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RecalculateBeginningOfPeriod(Val BeginOfPeriod, Val Periodicity, Val Offset, Val OffsetDirection)
	
	Offset = OffsetDirection * Offset;
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServerCached.CalculateStartDateOfPeriod(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetPeriodInWords(Val Offset, Val Periodicity, PeriodicityPresentation)

	PeriodicityPresentation = TargetValueMonitoringClientServer.PeriodInWords(Offset, Periodicity);

EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingPriceOption(Form)
	
	If Form.PricePopulationOption = "ItemsPrices" Then
		Form.Items.TypeOfPricePartner.Enabled 	= True;
		Form.Items.TypeOfPriceAgreement.Enabled= True;
		If Form.FillInPartner Or Form.FillInTermsOfSales Then
			Form.UsePriceType = True;
		EndIf;
	Else
		Form.Items.TypeOfPricePartner.Enabled 	= False;
		Form.Items.TypeOfPriceAgreement.Enabled= False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingUsePriceView(Form)
	
	If Form.UsePriceType Then
		Form.Items.PriceKind.Enabled = True;
	Else
		Form.Items.PriceKind.Enabled = False;
	EndIf;
	
	AdjustPriceOption(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingFillOption(Form)
	
	Form.Items.DecorationItemSelection.Enabled = Form.ContentFillingVariant = "Filter";
	Form.Items.FilterEmptyLines.Enabled = Form.ContentFillingVariant <> "Deficit";
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustPriceOption(Form)

	If Form.FillInPartner And Form.PricePopulationOption = "ItemsPricesOfVendor" And Not Form.FillInTermsOfSales Then
		Form.PricePopulationOption = "MinimumSupplierPrice";
	ElsIf Form.FillInTermsOfSales And Form.PricePopulationOption = "MinimumSupplierPrice" Then
		Form.PricePopulationOption = "ItemsPricesOfVendor";
	ElsIf Not Form.PricePopulationOption = "ItemsPrices" And Not Form.FillInPartner And Not Form.FillInTermsOfSales Then
		Form.PricePopulationOption = "ItemsPrices";
	EndIf;
	
	If Form.PricePopulationOption = "ItemsPrices"
		And (Form.FillInPartner Or Form.FillInTermsOfSales)
		And Form.PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		Form.UsePriceType = True;
	EndIf; 

EndProcedure

&AtServer
Procedure SetVisibilityOfFormPagesAndAccessibilityOfElements(EditMode, FillInByShortage)
	
	OptionsForFillingComposition = New Array;
	
	If PlanType = Enums.TypesOfPlans.SalesPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "GoodsPurchasedByTheCustomer";
		If FillInPartner Then
		
			Variant.Presentation = NStr("vi = 'theo hàng hóa do khách hàng mua';
										|ru = 'по товарам, приобретенным клиентом';
										|en = 'by goods purchased by customer'; fa = 'by goods purchased by customer';
										|it = 'per le merci acquistate dal cliente';
										|pl = 'wg towarów, nabytych przez klienta';
										|tr = 'ürünlere göre müşterinin edindiği'");
			Variant.LongDesc = NStr("vi = 'Toàn bộ mặt hàng do khách hàng được chọn trong chứng từ đã mua.';
									|ru = 'Вся номенклатура, приобретенная выбранным в документе клиентом.';
									|en = 'All products purchased by the customer specified in the document.'; fa = 'All products purchased by the customer specified in the document.';
									|it = 'Tutti gli articoli acquistati dal cliente selezionato nel documento.';
									|pl = 'Wszystkie towary, nabyte przez wybranego w dokumencie klienta';
									|tr = 'Müşterinin belgesinde seçilerek edinilebilen tüm ürünler.'");
		
		Else
		
			Variant.Presentation = NStr("vi = 'theo hàng hóa do tất cả khách hàng mua';
										|ru = 'по товарам, приобретенным всеми клиентами';
										|en = 'by goods purchased by all customers'; fa = 'by goods purchased by all customers';
										|it = 'per le merci acquistate da tutti i clienti';
										|pl = 'wg towarów, nabytych przez wszystkich klientów';
										|tr = 'ürünlere göre tüm müşterilerin edindikleri'");
			Variant.LongDesc = NStr("vi = 'Toàn bộ mặt hàng do tất cả khách hàng đã mua.';
									|ru = 'Вся номенклатура, приобретенная всеми клиентами.';
									|en = 'All products purchased by all customers.'; fa = 'All products purchased by all customers.';
									|it = 'Tutti gli articoli acquistati da tutti i clienti.';
									|pl = 'Wszystkie towary, nabyte przez wszystkich klientów.';
									|tr = 'Tüm müşterilerin edindikleri tüm ürünler.'");
		
		EndIf; 
		OptionsForFillingComposition.Add(Variant);
		
		If GetFunctionalOption("UseProductRange") Then
			
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "SalesAssortment";
			Variant.Presentation = NStr("vi = 'theo phân loại';
										|ru = 'по ассортименту';
										|en = 'by product range'; fa = 'بر اساس سبد محصولات';
										|it = 'su assortimento';
										|pl = 'wg asortymentu';
										|tr = 'ürün gamına göre'");
			Variant.LongDesc = NStr("vi = 'Cho phép điền mặt hàng theo danh điểm được phép bán hàng.';
									|ru = 'Позволяет заполнить номенклатуру по ассортименту, разрешенному к продаже.';
									|en = 'Allows you to fill in items by the product range allowed for sales.'; fa = 'Allows you to fill in items by the product range allowed for sales.';
									|it = 'Consente di compilare la nomenclatura per la gamma consentita alla vendita.';
									|pl = 'Pozwala wypełnić towary wg asortymentu, przeznaczonego do sprzedaży.';
									|tr = 'Ürün gamına göre bir satış çözümü olarak ürünlerin doldurulmasına izin verir.'");
			OptionsForFillingComposition.Add(Variant);
		
		EndIf; 
		
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		Items.GroupOptionForFillingInTheComposition.Title = NStr("vi = 'Điền thành phần thể loại hàng hóa theo:';
																|ru = 'Заполнять состав товарных категорий по:';
																|en = 'Fill in product categories by:'; fa = 'Fill in product categories by:';
																|it = 'Compilare la composizione delle categorie merceologiche per:';
																|pl = 'Wypełniaj skład kategorii towarowych wg:';
																|tr = 'Ürün kategorisi derlemesini şuna göre doldur:'");
		
		If FillInWarehouse Then
			
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "ProductCategoriesOfWarehouseFormat";
			Variant.Presentation = NStr("vi = 'theo tất cả thể loại hàng hóa';
										|ru = 'по всем товарным категориям';
										|en = 'by all product categories'; fa = 'by all product categories';
										|it = 'per tutte le categorie merceologiche';
										|pl = 'wg wszystkich kategorii towarowych';
										|tr = 'tüm ürün kategorilerine göre'");
			Variant.LongDesc = NStr("vi = 'Tất cả thể loại hàng hóa được bán trong kho (khuôn dạng cửa hàng).';
									|ru = 'Все товарные категории, которые участвовали в продажах на складе (в формате магазина).';
									|en = 'All product categories which participated in sales at warehouse (in the store format).'; fa = 'All product categories which participated in sales at warehouse (in the store format).';
									|it = 'Tutte le categorie merceologiche che hanno fatto parte alle vendite in magazzino (in formato negozio).';
									|pl = 'Wszystkie kategorie towarowe, które brały udział w sprzedażach w magazynie (w formacie magazynu).';
									|tr = 'Ambardaki satışlarda dahil edilen tüm ürün kategorileri (mağaza formatında).'");
			OptionsForFillingComposition.Add(Variant);
			
		
		Else
			
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "ProductCategories";
			Variant.Presentation = NStr("vi = 'theo tất cả thể loại hàng hóa';
										|ru = 'по всем товарным категориям';
										|en = 'by all product categories'; fa = 'by all product categories';
										|it = 'per tutte le categorie merceologiche';
										|pl = 'wg wszystkich kategorii towarowych';
										|tr = 'tüm ürün kategorilerine göre'");
			Variant.LongDesc = NStr("vi = 'Toàn bộ thể loại hàng hóa được bán.';
									|ru = 'Вся товарные категории, которые участвовали в продажах.';
									|en = 'All product categories which participated in sales.'; fa = 'All product categories which participated in sales.';
									|it = 'Tutte le categorie merceologiche che hanno fatto parte alle vendite.';
									|pl = 'Wszystkie kategorie towarowe, które brały udział w sprzedażach.';
									|tr = 'Satışlarda dahil edilen ürün kategorilerinin tümü.'");
			OptionsForFillingComposition.Add(Variant);
		
		EndIf; 
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "Formula";
		Variant.Presentation = NStr("vi = 'theo công thức';
									|ru = 'по формуле';
									|en = 'by formula'; fa = 'by formula';
									|it = 'secondo la formula';
									|pl = 'wg formuły';
									|tr = 'formüle göre'");
		Variant.LongDesc = NStr("vi = 'Thể loại hàng hóa sẽ được nhận từ đối tượng thao tác (nguồn) đã chỉ ra trong công thức dưới đây.';
								|ru = 'Товарные категории будут получены из операндов (источников), указанных в формуле ниже.';
								|en = 'Product categories will be received from operands (sources) specified in the formula below.'; fa = 'Product categories will be received from operands (sources) specified in the formula below.';
								|it = 'Le categorie merceologiche saranno derivate dagli operandi (fonti) indicati nella formula seguente.';
								|pl = 'Kategorie towarowe będą otrzymane z operandów (źródeł), wskazanych w poniższej formule.';
								|tr = 'Aşağıdaki formülde belirtilen ürün kategorileri işlenenden (kaynaktan) alınacaktır.'");
		OptionsForFillingComposition.Add(Variant);
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "Filter";
		Variant.Presentation = NStr("vi = 'theo bộ lọc';
									|ru = 'по отбору';
									|en = 'by filter'; fa = 'بر اساس فیلتر';
									|it = 'in base alla selezione';
									|pl = 'wg filtru';
									|tr = 'filtreye göre'");
		Variant.LongDesc = NStr("vi = 'Cho phép điền thể loại hàng hóa theo bộ lọc tùy ý đã đặt trong chứng từ.';
								|ru = 'Позволяет заполнить товарные категории по произвольным отборам, установленным в документе.';
								|en = 'Allows you to fill in the product categories by arbitrary filters set in the document.'; fa = 'Allows you to fill in the product categories by arbitrary filters set in the document.';
								|it = 'Consente compilare le categorie merceologiche in base alle selezioni arbitrarie impostate nel documento.';
								|pl = 'Pozwala wypełnić kategorie towarowe wg dowolnych wyborów, ustawionych w dokumencie.';
								|tr = 'İsteğe bağlı filtrelere göre belgeye kurulu ürün kategorilerinin doldurulmalarına izin verir.'");
		OptionsForFillingComposition.Add(Variant);
		
	ElsIf PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "AssemblyKitsOptions";
		Variant.Presentation = NStr("vi = 'theo bộ đóng gói';
									|ru = 'по собираемым комплектам';
									|en = 'by assembled kits'; fa = 'by assembled kits';
									|it = 'per i set assemblati';
									|pl = 'wg montowanych kompletów';
									|tr = 'toplanan ürün setlerine göre'");
		Variant.LongDesc = NStr("vi = 'Mặt hàng mà đã tạo ít nhất một phương án đóng bộ.';
								|ru = 'Номенклатура, для которой создан хотя бы один вариант комплектации.';
								|en = 'Items that have one or more product kit configurations created.'; fa = 'Items that have one or more product kit configurations created.';
								|it = 'La nomenclatura per la quale è stata creata almeno una versione di configurazione.';
								|pl = 'Towary, dla których utworzono chociażby jeden wariant kompletacji.';
								|tr = 'Kendisi için en az bir set konfigürasyonu oluşturulan öğe.'");
		OptionsForFillingComposition.Add(Variant);
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "AssemblyKits";
		Variant.Presentation = NStr("vi = 'dựa trên việc sử dụng trong lắp ráp';
									|ru = 'по признаку использования в сборке';
									|en = 'by attribute indicating that it is included in kitting'; fa = 'by attribute indicating that it is included in kitting';
									|it = 'sulla base dell''uso nell''assemblaggio';
									|pl = 'wg cechy użycia w montażu';
									|tr = 'montajda kullanılan işarete göre'");
		Variant.LongDesc = NStr("vi = 'Cho phép điền mặt hàng chưa bao giờ tập hợp.';
								|ru = 'Позволяет заполнить номенклатуру, которая когда-либо собиралась.';
								|en = 'Allows you to fill in items which were assembled at any time.'; fa = 'Allows you to fill in items which were assembled at any time.';
								|it = 'Consente compilare la nomenclatura che è stata mai assemblata.';
								|pl = 'Pozwala wypełnić towary, które kiedykolwiek były montowane.';
								|tr = 'Şimdiye kadar oluşturulan ürünlerin doldurulmalarına izin verir.'");
		OptionsForFillingComposition.Add(Variant);
		
	ElsIf PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "GoodsWrittenOffForDomesticNeeds";
		Variant.Presentation = NStr("vi = 'dựa trên việc ghi giảm';
									|ru = 'по признаку списания на расходы';
									|en = 'by the flag of write-off as expenses'; fa = 'by the flag of write-off as expenses';
									|it = 'per indicazione di storno sulla voce di spese';
									|pl = 'wg oznaki spisania na rozchody';
									|tr = 'giderlerde kayıtlı olan işarete göre'");
		Variant.LongDesc = NStr("vi = 'Cho phép điền hàng hóa đã từng được ghi giảm để đảm bảo nhu cầu nội bộ.';
								|ru = 'Позволяет заполнить товары, которые когда-либо списывались на обеспечение внутренних потребностей.';
								|en = 'Fill in the goods that have ever been written off for internal needs.'; fa = 'Fill in the goods that have ever been written off for internal needs.';
								|it = 'Permette di compilare le merci che sono state stornate per gli approvvigionamenti interni.';
								|pl = 'Pozwala wypełnić towary, które kiedykolwiek byli rozchodowane do zaopatrzenia konsumpcji wewnętrznych.';
								|tr = 'Şimdiye kadar yazılan stok tüketim talebinin karşılanmasına ürünleri doldurarak izin verir.'");
		OptionsForFillingComposition.Add(Variant);
	ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "ManufacturedProducts";
		Variant.Presentation = NStr("vi = 'cho các sản phẩm sản xuất';
									|ru = 'по производимой продукции';
									|en = 'by manufactured products'; fa = 'by manufactured products';
									|it = 'per i prodotti fabbricati';
									|pl = 'wg wytwarzanej produkcji';
									|tr = 'ürün üretimine göre'");
		Variant.LongDesc = NStr("vi = 'Cho phép điền mặt hàng chưa bao giờ sản xuất.';
								|ru = 'Позволяет заполнить номенклатуру, которая когда-либо производилась.';
								|en = 'Allows you to fill in items which were manufactured at any time.'; fa = 'Allows you to fill in items which were manufactured at any time.';
								|it = 'Consente compilare la nomenclatura che è stata mai fabbricata.';
								|pl = 'Pozwala wypełnić towary, które kiedykolwiek były produkowane.';
								|tr = 'Şimdiye kadar üretilen ürünlerin doldurulmalarına izin verir.'");
		OptionsForFillingComposition.Add(Variant);
	ElsIf PlanType = Enums.TypesOfPlans.PurchasePlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "ProductCrossReferences";
		If FillInPartner Then
			Variant.Presentation = NStr("vi = 'theo hàng hóa nhà cung cấp';
										|ru = 'по номенклатуре поставщика';
										|en = 'by vendor part number'; fa = 'بر اساس شماره قطعه تأمین‌کننده';
										|it = 'articolo fornitore';
										|pl = 'wg  nomenklatury dostawcy';
										|tr = 'tedarikçi parça numaralarına göre'");
			Variant.LongDesc = NStr("vi = 'Cho phép điền theo mặt hàng đã ghi nhận của nhà cung cấp.';
									|ru = 'Позволяет заполнить по зарегистрированной номенклатуре поставщика.';
									|en = 'Allows you to fill in items by the vendor''s part numbers'; fa = 'امکان پرکردن اقلام بر اساس شماره‌های قطعه تأمین‌کننده را فراهم می‌کند';
									|it = 'Consente di compilare l''articolo del fornitore registrato.';
									|pl = 'Pozwala wypełnić według zarejestrowanej  nomenklatury dostawcy.';
									|tr = 'Tedarikçinin ürünlerinin kayıtlandırmalarına göre doldurulmasına izin verir.'");
		Else
			Variant.Presentation = NStr("vi = 'theo toàn bộ mặt hàng của nhà cung cấp';
										|ru = 'по всей номенклатуре поставщиков';
										|en = 'by all vendors'' part numbers'; fa = 'by all vendors'' part numbers';
										|it = 'in base all''intera nomenclatura dei fornitori';
										|pl = 'wg wszystkich towarów dostawców';
										|tr = 'tedarikçinin tüm ürünlerine göre'");
			Variant.LongDesc = NStr("vi = 'Cho phép điền theo mặt hàng đã ghi nhận của tất cả nhà cung cấp.';
									|ru = 'Позволяет заполнить по зарегистрированной номенклатуре всех поставщиков.';
									|en = 'Allows you to fill in items by part numbers of all vendors.'; fa = 'Allows you to fill in items by part numbers of all vendors.';
									|it = 'Consente di compilare secondo la nomenclatura registrata di tutti i fornitori.';
									|pl = 'Pozwala wypełniać wg zarejestrowanych towarów wszystkich dostawców.';
									|tr = 'Tüm tedarikçilerin kayıtlı ürünlerine göre doldurmaya izin verir.'");
		EndIf;
		OptionsForFillingComposition.Add(Variant);
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "GoodsPurchasedFromSupplier";
		If FillInPartner Then
			Variant.Presentation = NStr("vi = 'theo hàng hóa mua của nhà cung cấp';
										|ru = 'по товарам, приобретенным у поставщика';
										|en = 'by goods purchased from the vendor'; fa = 'بر اساس کالاهای خریداری‌شده از تأمین‌کننده';
										|it = 'articoli acquistati dal fornitore';
										|pl = 'wg towarów, nabytych u dostawcy';
										|tr = 'ürünlere göre tedarikçiden satın alınan'");
			Variant.LongDesc = NStr("vi = 'Toàn bộ mặt hàng đã mua từ nhà cung cấp được chọn.';
									|ru = 'Вся номенклатура, приобретенная у выбранного поставщика.';
									|en = 'All products purchased from the selected vendor.'; fa = 'همه محصولات خریداری‌شده از تأمین‌کننده انتخاب‌شده.';
									|it = 'Tutti gli articoli acquistati dal fornitore selezionato.';
									|pl = 'Wszystkie towary, nabyte u wybranego dostawcy.';
									|tr = 'Seçilen tedarikçiden satın alınan ürünlerin tamamı.'");
		Else
			Variant.Presentation = NStr("vi = 'theo hàng hóa đã mua từ tất cả nhà cung cấp';
										|ru = 'по товарам, приобретенным у всех поставщиков';
										|en = 'by goods purchased from all vendors'; fa = 'by goods purchased from all vendors';
										|it = 'per le merci acquistate da tutti i fornitori';
										|pl = 'wg towarów, nabytych u wszystkich dostawców';
										|tr = 'ürünlere göre tüm tedarikçilerden satın alınan'");
			Variant.LongDesc = NStr("vi = 'Toàn bộ mặt hàng đã mua từ nhà cung cấp.';
									|ru = 'Вся номенклатура, приобретенная у всех поставщиков.';
									|en = 'All products purchased from all vendors.'; fa = 'All products purchased from all vendors.';
									|it = 'Tutta la nomenclatura acquistata da tutti i fornitori.';
									|pl = 'Wszystkie towary, nabyte u wszystkich dostawców.';
									|tr = 'Tüm tedarikçilerden satın alınan tüm ürünler.'");
		EndIf;
		OptionsForFillingComposition.Add(Variant);
		
		If GetFunctionalOption("UseProductRange") Then
			
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "PurchaseAssortment";
			Variant.Presentation = NStr("vi = 'theo phân loại';
										|ru = 'по ассортименту';
										|en = 'by product range'; fa = 'بر اساس سبد محصولات';
										|it = 'su assortimento';
										|pl = 'wg asortymentu';
										|tr = 'ürün gamına göre'");
			Variant.LongDesc = NStr("vi = 'Cho phép điền mặt hàng theo danh điểm được phép mua hàng.';
									|ru = 'Позволяет заполнить номенклатуру по ассортименту, разрешенному к закупкам.';
									|en = 'Allows you to fill in items by the product range allowed for purchase.'; fa = 'امکان پرکردن اقلام بر اساس سبد محصولات مجاز برای خرید را فراهم می‌کند.';
									|it = 'Consente di riempire un articolo di gamma, consentito agli appalti.';
									|pl = 'Pozwala wypełnić towary wg asortymentu, przeznaczonego do zakupu.';
									|tr = 'Ürünlerin, satın alınmasına izin verilen ürün gamına göre doldurulmasına imkân tanır.'");
			OptionsForFillingComposition.Add(Variant);
		
		EndIf;
		
	EndIf;
	
	If (PlanType = Enums.TypesOfPlans.SalesPlan
		Or PlanType = Enums.TypesOfPlans.ProductionPlan
		Or PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan
		Or PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan
		Or PlanType = Enums.TypesOfPlans.PurchasePlan
		Or PlanType = Enums.TypesOfPlans.PlanOfGoodsStock) Then
		
		If Not FillInByShortage Then
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "Formula";
			Variant.Presentation = NStr("vi = 'từ công thức';
										|ru = 'из формулы';
										|en = 'from formula'; fa = 'از فرمول';
										|it = 'dalla formula';
										|pl = 'z formuły';
										|tr = 'formülden'");
			Variant.LongDesc = NStr("vi = 'Sẽ nhận mặt hàng từ các toán hạng mà được chỉ ra trong công thức dưới đây.';
									|ru = 'Номенклатура будет получена из операндов, указанных в формуле ниже.';
									|en = 'Item will be received from the operands specified in the formula below.'; fa = 'Item will be received from the operands specified in the formula below.';
									|it = 'L''articolo verrà ricevuto dagli operandi specificati nella formula seguente.';
									|pl = 'Produkt będzie pobrany z operandów, wskazanych w formule poniżej.';
									|tr = 'Ürünler önceki formülde belirtilen işlenenden alınacak.'");
			OptionsForFillingComposition.Add(Variant);
		EndIf;
		
		If Not EditMode Then
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "DoNotChange";
			Variant.Presentation = NStr("vi = 'không thay đổi';
										|ru = 'не менять';
										|en = 'do not change'; fa = 'تغییر داده نشود';
										|it = 'non cambiare';
										|pl = 'nie zmieniaj';
										|tr = 'değiştirme'");
			Variant.LongDesc = NStr("vi = 'Thành phần của mặt hàng từ kế hoạch không thay đổi.';
									|ru = 'Состав номенклатуры из плана не меняется.';
									|en = 'Product content from plan is not changed.'; fa = 'محتوای محصول از برنامه تغییر نمی‌کند.';
									|it = 'La composizione di articoli dal piano non cambia.';
									|pl = 'Skład nomenklatury z planu nie jest zmieniany.';
									|tr = 'Plandan ürünlerin derlemesi değiştirilmiyor.'");
			OptionsForFillingComposition.Add(Variant);
			
			Variant = New Structure("Source, Presentation, LongDesc");
			Variant.Source = "Filter";
			Variant.Presentation = NStr("vi = 'theo bộ lọc';
										|ru = 'по отбору';
										|en = 'by filter'; fa = 'بر اساس فیلتر';
										|it = 'in base alla selezione';
										|pl = 'wg filtru';
										|tr = 'filtreye göre'");
			Variant.LongDesc = NStr("vi = 'Cho phép điền mặt hàng theo bộ lọc tùy ý đã đặt trong chứng từ.';
									|ru = 'Позволяет заполнить номенклатуру по произвольным отборам, установленным в документе.';
									|en = 'Allows you to fill in the products by the arbitrary filters set in the document.'; fa = 'امکان پرکردن محصولات بر اساس فیلترهای دلخواه تنظیم‌شده در سند را فراهم می‌کند.';
									|it = 'Consente di compilare l''articolo con selezioni libere impostate nel documento.';
									|pl = 'Pozwala wypełnić nomenklaturę według dowolnego filtru, ustawionego w dokumencie.';
									|tr = 'İsteğe bağlı filtrelere göre dosyaya kurulu ürünlerin doldurulmalarına izin verir.'");
			OptionsForFillingComposition.Add(Variant);
		EndIf;
	
	EndIf;
	
	If FillInByShortage Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "Deficit";
		Variant.Presentation = NStr("vi = 'thâm hụt';
									|ru = 'по дефициту';
									|en = 'by shortage'; fa = 'by shortage';
									|it = 'per deficit';
									|pl = 'według niedoboru';
									|tr = 'mali açığa göre'");
		Variant.LongDesc = NStr("vi = 'Điền mặt hàng có thâm hụt bởi các kế hoạch khác.';
								|ru = 'Заполняет номенклатуру по которой имеется дефицит, сформированный другими планам.';
								|en = 'Fills in the products with a shortage caused by other plans.'; fa = 'Fills in the products with a shortage caused by other plans.';
								|it = 'Compila gli articoli per cui c''è il deficit generato da altri piani.';
								|pl = 'Wypełnia nomenklaturę, według której występuje niedobór, utworzony innymi planami.';
								|tr = 'Mali açığa sahip olan ürünleri doldurur, diğer planlar tarafından oluşturulmuştur.'");
		OptionsForFillingComposition.Add(Variant);
		
	EndIf;
	
	Items.ContentFillingVariant.ChoiceList.Clear();
	
	IndexOf = 1;
	For Each Variant In OptionsForFillingComposition Do
		
		If Variant.Source =  "Filter" Then
			Continue;
		EndIf;
		
		Items.ContentFillingVariant.ChoiceList.Add(Variant.Source, Variant.Presentation);
		ElementFillingOptionCompositionExplanation = Items["OptionOfFillingInCompositionExplanation"+IndexOf]; // FormDecoration - 
		Variant.Property("LongDesc", ElementFillingOptionCompositionExplanation.Title);
		IndexOf = IndexOf + 1;
	EndDo;
	
	While IndexOf <= 5 Do
	
		Items["OptionOfFillingInCompositionExplanation"+IndexOf].Visible = False;
		IndexOf = IndexOf + 1;
	
	EndDo; 
	
	Items.GroupTypeOfPurchasePrice.Visible = False;
	Items.PriceGroupPartner.Visible = False;
	Items.GroupPricesAgreement.Visible = False;
	
	Items.FilterByAvailabilityOfBOM.Visible = False;
	Items.FilterByAvailabilityOfBOM.Visible = (PlanType = Enums.TypesOfPlans.ProductionPlan);
	If PlanType = Enums.TypesOfPlans.SalesPlan And PlanByAmount Then
		Items.GroupTypeOfPurchasePrice.Visible = True;
	ElsIf PlanType = Enums.TypesOfPlans.PurchasePlan And PlanByAmount Then
	
		If FillInPartner Then
		
			If FillInTermsOfSales Then
				Items.GroupPricesAgreement.Visible = True;
			Else
				Items.PriceGroupPartner.Visible = True;
			EndIf;
		
		Else
		
			Items.GroupTypeOfPurchasePrice.Visible = True;
		
		EndIf; 
	
	EndIf;
	
	SetAvailabilityOfOffsetSetting(ThisForm);
	
	WhenOffsetChanges(ThisForm);
	UpdatePeriodWhenOffsetChanges(ThisObject);
	WhenChangingPriceOption(ThisForm);
	WhenChangingUsePriceView(ThisForm);
	WhenChangingFillOption(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfOffsetSetting(Form)
	
	If StrFind(Form.Formula , "PlannedStartBalance") <> 0
		Or StrFind(Form.Formula , "PlannedFinalBalances") <> 0
		Or StrFind(Form.Formula , "PlannedFinalDeficit") <> 0 Then
		
		Form.OffsetOption = "CurrentPeriod";
		Form.EditedOffset = 0;
		Form.Items.GroupCommentDoNotUseOffset.Visible = Form.Items.OffsetGroup.Visible;
		
		Form.Items.OffsetOptionPreviousPeriod.Enabled = False;
		Form.Items.TheOptionOffsetPriorYear.Enabled = False;
		Form.Items.GroupOffsetOptionArbitrary.Enabled = False;
		
	Else
		Form.Items.GroupCommentDoNotUseOffset.Visible = False;
		
		Form.Items.OffsetOptionPreviousPeriod.Enabled = True;
		Form.Items.TheOptionOffsetPriorYear.Enabled = True;
		Form.Items.GroupOffsetOptionArbitrary.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFormulaEditingDialog()
	
	FormParameters = New Structure();
	FormParameters.Insert("Advanced",True);
	FormParameters.Insert("EnableValue",False);
	FormParameters.Insert("Formula",?(Formula = NStr("vi = 'Đặt công thức';
													|ru = 'Задать формулу';
													|en = 'Set formula'; fa = 'Set formula';
													|it = 'Impostare la formula';
													|pl = 'Wyznacz formułę';
													|tr = 'Formül sor'"),"", Formula));
	FormParameters.Insert("Presentation",?(FormulaPresentation = PlanningClientServer.TextForSettingNewFormula(),
		"", FormulaPresentation));
	FormParameters.Insert("OperandsTree",PlaceAdditionalFieldsInStorage());
	FormParameters.Insert("Operators",OperatorsTreeStorageAddress);
	FormParameters.Insert("ResultType", New TypeDescription("Number"));
	FormParameters.Insert("FunctionsFromCommonModule", PlanningClient.FunctionsFromCommonModule());
	FormParameters.Insert("SavedSettingsObjectKey", "UserSettings_" + PlanType);
	FormParameters.Insert("Filter", Filter);
	
	CallbackDescription = New CallbackDescription("SpecifyArbitraryFormula",ThisObject);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.FormulasConstructor", FormParameters, ThisForm,,,,CallbackDescription,Mode);
	
EndProcedure

&AtClient
Procedure SpecifyArbitraryFormula(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If EditedOffset <> 0 
		And (StrFind(Result.Formula , "PlannedStartBalance")<>0
		Or StrFind(Result.Formula , "PlannedFinalBalances")<>0
		Or StrFind(Result.Formula , "PlannedFinalDeficit")<>0) Then
		
		QueryText = NStr("vi = 'Công thức chứa một toán hạng để tính toán số dư theo kế hoạch, dữ liệu chỉ có thể được lấy từ giai đoạn hiện tại. Thay đổi cài đặt bù hiện tại và tiếp tục?';
						|ru = 'В формуле присутствует операнд по вычислению планируемого остатка, данные могут быть получены только из текущего периода. Изменить текущие настройки смещения и продолжить?';
						|en = 'There is an operand for planned balance calculation in the formula, the data can be received only from the current period. Change the current offset settings and continue?'; fa = 'There is an operand for planned balance calculation in the formula, the data can be received only from the current period. Change the current offset settings and continue?';
						|it = 'La formula contiene un operando per il calcolo del saldo programmato, i dati possono essere rilevati solo dal periodo corrente. Modificare le impostazioni attuali di scostamento e continuare?';
						|pl = 'Formuła zawiera operand do obliczania planowanego salda, dane można uzyskać tylko z bieżącego okresu. Zmienić bieżące ustawienia przesunięcia i kontynuować?';
						|tr = 'Planlanan bakiyeye göre formülde bir işlenen mevcut, veriler sadece mevcut dönemden alınabilir. Mevcut kayma ayarları değiştirilsin ve devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("SpecifyArbitraryFormulaCompletion", ThisObject, Result), 
				QueryText, QuestionDialogMode.YesNo);
	Else
		Formula = ?(ValueIsFilled(Result.Formula), Result.Formula, PlanningClientServer.TextForSettingNewFormula());
		FormulaPresentation = ?(ValueIsFilled(Result.Presentation) 
		And Formula <> PlanningClientServer.TextForSettingNewFormula(), Result.Presentation, Formula);
		
		SetAvailabilityOfOffsetSetting(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyArbitraryFormulaCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = AdditionalParameters;
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		Formula = ?(ValueIsFilled(Result.Formula), Result.Formula, PlanningClientServer.TextForSettingNewFormula());
		FormulaPresentation = ?(ValueIsFilled(Result.Presentation) 
		And Formula <> PlanningClientServer.TextForSettingNewFormula(), Result.Presentation, Formula);
		
		SetAvailabilityOfOffsetSetting(ThisForm);
		UpdatePeriodWhenOffsetChanges(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Function PlaceAdditionalFieldsInStorage()
	
	Return Planning.PlaceAdditionalFieldsInStorage(ThisForm, 0);
	
EndFunction

&AtClient
Procedure ShouldSaveSettings()
	
	FillPropertyValues(SettingsStructure, ThisObject);
	SettingsStructure.Insert("SelectionOfProductsSettings", SelectionOfProductsSettings());
	SettingsStructure.Insert("FilterEmptyLines", ThisObject.FilterEmptyLines);
	SettingsStructure.Insert("FilterByAvailabilityOfBOM", ThisObject.FilterByAvailabilityOfBOM);
	
	SaveSettingsAtServer(SettingsStructure, PlanType);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(SettingsStructure, PlanType)
	
	ObjectKey = "UserSettings_" + PlanType;
	Common.CommonSettingsStorageSave(ObjectKey, "SettingsStructure", SettingsStructure);
	
EndProcedure

&AtClient
Procedure DecorationItemSelectionURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or Not IsTempStorageURL(Result) Then
		Return;
	EndIf;
	ProcessProductSelectionChanges(Result);
	
EndProcedure

&AtServer
Function SelectionOfProductsSettings()
	Return FilterOfProductItem.GetSettings();	
EndFunction

&AtServer
Procedure ProcessProductSelectionChanges(FilterAddress)
	
	SelectionOfProductsSetting = GetFromTempStorage(FilterAddress);
	DeleteFromTempStorage(FilterAddress);
	
	FilterOfProductItem.LoadSettings(SelectionOfProductsSetting);
	CreatePresentationOfProductSelection();
	
EndProcedure

&AtServer
Procedure CreatePresentationOfProductSelection()
	
	RowsArray = New Array;
	//Array of strings.Add("Selection of nomenclature: ");
	FilterPresentation = String(FilterOfProductItem.Settings.Filter);
	If ValueIsFilled(FilterPresentation) Then
		RowsArray.Add(New FormattedString(NStr("vi = 'thay đổi';
												|ru = 'изменить';
												|en = 'change'; fa = 'change';
												|it = 'modificare';
												|pl = 'change';
												|tr = 'değiştir'"),,,,"Filter"));
	Else
		RowsArray.Add(New FormattedString(NStr("vi = 'chưa đặt';
												|ru = 'не установлен';
												|en = 'not set'; fa = 'not set';
												|it = 'non impostato';
												|pl = 'nie ustawiono';
												|tr = 'kurulmamış'"),,,,"Filter"));
	EndIf;
	Items.DecorationItemSelection.Title = New FormattedString(RowsArray);
	
EndProcedure

#EndRegion
