#Region Variables

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	ForceCloseTheForm = True;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	UsePriceManagementSystem25                 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UseSeveralPriceTypes                 = GetFunctionalOption("UseSeveralPriceTypes");
	UseMultipleCurrencies                    = GetFunctionalOption("UseMultipleCurrencies");
	UseProduction                      = GetFunctionalOption("UseProduction");
	UsePriceGroups                     = GetFunctionalOption("UsePriceGroups");
	UseCustomerInvoiceIntercompany = GetFunctionalOption("UseCustomerInvoiceIntercompany");
	UseCompetitiveIntelligence              = GetFunctionalOption("UseCompetitiveIntelligence");
	UseIntegrationWithYandexMarket           = False;
	UseIntegrationWithOzon                   = False;
	PriceTypeApproval                           = UserRightsCached.PriceTypeApproval();
	
	UnsafeWaysToSetPrices.LoadValues(Enums.PriceSettingMethods.UnsafeWaysToSetPrices());
	
	
	If UsePriceManagementSystem25 Then
		TypicalScheme = Metadata.Catalogs.TypesOfPrices.Templates.Typical2_5.Name;
	Else
		TypicalScheme = Metadata.Catalogs.TypesOfPrices.Templates.Typical.Name;
	EndIf;
		ScheduledPriceCurrency = Constants.PlannedPriceCurrencyOfProductsMaterialsAndLabor.Get();
	If Not UseSeveralPriceTypes Then
		ThisForm.AutoTitle = False;
		ThisForm.Title = NStr("vi = 'Tham số bảng giá';
								|ru = 'Параметры прайс-листа';
								|en = 'Price list parameters'; fa = 'پارامترهای لیست قیمت';
								|it = 'Parametri listino prezzi';
								|pl = 'Parametry cennika';
								|tr = 'Fiyat listesi parametreleri'");
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If UseSeveralPriceTypes Then
		// Subsystem prohibiting editing of key details of objects
		ObjectAttributesLock.LockAttributes(ThisForm);
	EndIf;
	
	SettingCompliance = New Structure;
	PreviousPricingMethod = Object.PricingMethod;
	PreviousDataCompositionSchema = Object.DataCompositionSchema;
	If ValueIsFilled(Object.Ref) Then
		DetailsOfSettingsStore = Common.ObjectAttributesValues(Object.Ref,
			"StorageOfDataCompositionSettings, StorageOfDataCompositionSchema, StorageOfFilterByItemsDataCompositionSettings");
		StorageOfDataCompositionSettings = DetailsOfSettingsStore.StorageOfDataCompositionSettings; 
		StorageOfDataCompositionSchema = DetailsOfSettingsStore.StorageOfDataCompositionSchema;
	Else
		StorageOfDataCompositionSettings = New ValueStorage(Undefined); 
		StorageOfDataCompositionSchema = New ValueStorage(Undefined);
	EndIf;
	SettingsStorageVariable = StorageOfDataCompositionSettings; // ValueStorage
	ComposerSettings = SettingsStorageVariable.Get();
	ArbitraryFilterIsUsed = ComposerSettings <> Undefined;

	If ArbitraryFilterIsUsed Then
		SettingsComposer.LoadSettings(ComposerSettings);
	ElsIf ValueIsFilled(Object.DataCompositionSchema) Then
		DescriptionDataLayoutDiagram = SettingPricesCached.GetDescriptionAndLayoutDiagramOfDataByTemplateName(Object.DataCompositionSchema, UsePriceManagementSystem25);
		InitializeSettingsComposer(DescriptionDataLayoutDiagram.DataCompositionSchema);
	EndIf;
	
	UpdateDataLayoutPresentation();
	SetParametersForCalculationRules();
	
	InitializeSettingsAccordingToMethodOfSettingPrice();
	
	DCSSchemeCompliance = New Structure;
	DCSSchemeCompliance.Insert(StrReplace(String(Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors)," ",""), "CompetitorPricesPredefined");
	DCSSchemeCompliance.Insert(StrReplace(String(Enums.PriceSettingMethods.FillInByInfobaseDataByVendors)," ",""), "VendorPricesPredefined");
	DCSSchemeCompliance.Insert(StrReplace(String(Enums.PriceSettingMethods.FillByInfobaseDataByCost)," ",""), "CostPredefined");
	DCSSchemeCompliance.Insert(StrReplace(String(Enums.PriceSettingMethods.MarkupOnPurchasingPrice)," ",""), "ReceiptPricesPredefined");
	DCSSchemeCompliance.Insert(StrReplace(String(Enums.PriceSettingMethods.MarkupOnOBEntryPrice)," ",""), "PricesOBEntryPredefined");

// we fill in the selection by nomenclature, if there is
	ComposerSettings = Undefined;	
	If ValueIsFilled(Object.Ref) Then
		StorageOfFilterByItemsDataCompositionSettings = DetailsOfSettingsStore.StorageOfFilterByItemsDataCompositionSettings;
	Else
		StorageOfFilterByItemsDataCompositionSettings = New ValueStorage(Undefined);	
	EndIf;
	SettingsStorageVariable = StorageOfFilterByItemsDataCompositionSettings; // ValueStorage
	ComposerSettings = SettingsStorageVariable.Get();
	If ComposerSettings <> Undefined Then
		SettingsComposerFilterByProducts.LoadSettings(ComposerSettings);
	EndIf;
	UpdateProductSelectionPresentation();
	
	UseAdvancedRoundingSetting = AdvancedRoundingSettingsAreUsed(ThisForm);
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	ConfigureTableRoundingRuleServer(ThisForm);
	
	CustomizeForm();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	SetValueOfMarginsDiscounts();

	SetAvailabilityAuxiliaryPrice(ThisForm);
	
	UpdatePresentationToClarifyValueOfMarkUpDiscount();
	
	UpdatePresentationUpdateTriggerThresholds();

	UpdateCurrencyRefinementPresentation();
	
	UpdatePresentationRefinementOfRoundingSettings();
	
	UpdateSalesDepthPresentation();
	
	UpdateUseResponseThresholdsCheckbox();

	AdjustVisibilityAvailabilityOfThresholdSettings(ThisForm);
	
	UpdateDataOnOwnerOfIndividualPriceType();
	
	AdjustVisibilityAvailabilityOfItemsWhenChangingTypeOfPriceView(ThisForm);
	
	UseMultiCountryAccounting = TMCommonUseCached.ConstantValue("UseMultiCountryAccounting");
	Items.Country.Visible = UsePriceManagementSystem25 And UseMultiCountryAccounting;
	AdjustVisibilityOfVATRatesElements(ThisObject, True);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure InitializeSettingsAccordingToMethodOfSettingPrice(ChangedWayPricesAreSet = False)
	
	If ChangedWayPricesAreSet Then 
		SettingsByMethodOfSettingPrice = Undefined;  
		
		ParametersOfPriceSettingMethod = Undefined;
		ParametersOfPriceSettingMethodAddOn = Undefined;  
		ParametersOfPriceSettingMethodCustomType = Undefined;
		ParametersOfPriceSettingMethodSelectionList = Undefined;
	Else
		StorageAttributes = Common.ObjectAttributeValue(Object.Ref, "StorageOfPricingMethodParametersSettings"); // ValueStorage 
		SettingsStorageVariable = ?(ValueIsFilled(StorageAttributes), 
			StorageAttributes, New ValueStorage(Undefined));
		StorageOfPricingMethodParametersSettings = SettingsStorageVariable;
		SettingsByMethodOfSettingPrice = SettingsStorageVariable.Get();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AddSuggestedIdValueToSelectionList();
	
	CreateListToSelectPriceTypeAssignments();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If PriceTypeApproval // If the user does not have recording rights, then there is no point in asking him a question
		And Object.Status = PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid")
		And ThisIsUnsafeWayToSetPrice(Object.PricingMethod, UnsafeWaysToSetPrices)
		And Not ConfirmationOfUnsafeRecordHasBeenReceived Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		CallbackDescription = New CallbackDescription(
			"AfterSecurityConfirmationQuestion",
			ThisObject,
			AdditionalParameters);
		
		QueryText = NStr("vi = 'Phương pháp đặt giá đã chọn có thể chứa thuật toán tùy ý.
		|Bạn có xác nhận tính an toàn và việc sử dụng nó không?';
		|ru = 'Выбранный способ задания цены может содержать произвольный алгоритм.
		|Подтверждаете его безопасность и использование?';
		|en = 'The selected pricing method may contain an arbitrary algorithm.
		|Do you confirm its safety and use?'; fa = 'The selected pricing method may contain an arbitrary algorithm.
		|Do you confirm its safety and use?';
		|it = 'The selected pricing method may contain an arbitrary algorithm.
		|Do you confirm its safety and use?';
		|pl = 'The selected pricing method may contain an arbitrary algorithm.
		|Do you confirm its safety and use?';
		|tr = 'Seçili fiyatlandırma yöntemi, opsiyonel bir algoritma içeriyor olabilir.
		|Güvenliğini ve kullanımını doğrulamakta mısınız?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.PriceRoundingRules.Count() > 0 Then
		If CurrentObject.Round And CurrentObject.PriceRoundingRules.Count() = 1
			And CurrentObject.PriceRoundingRules[0].LowerBoundOfPriceRange = 0
			And CurrentObject.PriceRoundingRules[0].SmartRounding = 0 Then
				
			CurrentObject.RoundingPrecision = CurrentObject.PriceRoundingRules[0].RoundingPrecision;
			
			CurrentObject.Round = Not (CurrentObject.RoundingPrecision = 0);
			
		EndIf;
	Else
		CurrentObject.Round = False;
	EndIf;
			
	If Not CurrentObject.Round And CurrentObject.PriceRoundingRules.Count() > 0 Then
		CurrentObject.PriceRoundingRules.Clear();
		CurrentObject.RoundingPrecision = 0;
	EndIf;
	
	CurrentObject.InfluencingPriceTypes.Clear();
	
	If CurrentObject.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
		Or CurrentObject.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt 
		Or CurrentObject.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
		Or CurrentObject.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
		Or CurrentObject.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
		
		If Not ValueIsFilled(Object.DataCompositionSchema) Then
			If StorageOfDataCompositionSchema <> Undefined Then
				SchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
				If Not PriceManagementSystem.CheckDataLayoutScheme(SchemaStorage.Get()) Then
					Cancel = True;
				EndIf;
			Else
				Common.MessageToUser(NStr("vi = 'Cần tùy chỉnh sơ đồ dàn dựng dữ liệu để điền đơn giá.';
											|ru = 'Необходимо настроить схему компоновки данных для заполнения цен.';
											|en = 'Configure data composition schema for price population.'; fa = 'Configure data composition schema for price population.';
											|it = 'È necessario impostare uno schema di composizione dei dati per compilare i prezzi.';
											|pl = 'Jest wymagane ustawienie schematu układu danych do wypełniania cen.';
											|tr = 'Fiyatların doldurulması için veri inşa edilme şemasını ayarlamanız gerekmektedir.'"), Object.Ref,,,Cancel);
			EndIf;
		EndIf;
		
		CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
		CurrentObject.StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
		
	ElsIf CurrentObject.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
		
		If UsePriceGroups Then
			
			For Each TSRow In CurrentObject.PriceGroups Do
				Catalogs.TypesOfPrices.ExtractBasePricesFromFormula(CurrentObject, AvailableBasicPriceTypes, TSRow.Formula, Cancel);
			EndDo;
			
			If Cancel Then
				Common.MessageToUser(NStr("vi = 'Trong dạng giá, đã chỉ ra dạng giá ảnh hưởng không chính xác. Hãy kiểm tra công thức hoặc dạng giá cơ bản.';
											|ru = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
											|en = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.'; fa = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
											|it = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
											|pl = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
											|tr = 'Fiyat türünde yanlış bir etkileyen fiyat türü belirtildi. Formülleri veya temel fiyat türünü kontrol edin.'"), Object.Ref,,,Cancel);
			EndIf;

		EndIf;
		
		Catalogs.TypesOfPrices.ExtractBasePricesFromFormula(CurrentObject, AvailableBasicPriceTypes, CurrentObject.Formula, Cancel);
		If Cancel Then
			Common.MessageToUser(NStr("vi = 'Trong dạng giá, đã chỉ ra dạng giá ảnh hưởng không chính xác. Hãy kiểm tra công thức hoặc dạng giá cơ bản.';
										|ru = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
										|en = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.'; fa = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
										|it = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
										|pl = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
										|tr = 'Fiyat türünde yanlış bir etkileyen fiyat türü belirtildi. Formülleri veya temel fiyat türünü kontrol edin.'"), Object.Ref,,,Cancel);
		EndIf;
		
		If Not ValueIsFilled(Object.DataCompositionSchema) Then
			SchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
			If StorageOfDataCompositionSchema <> Undefined And SchemaStorage.Get() <> Undefined Then
				If Not PriceManagementSystem.CheckDataLayoutScheme(SchemaStorage.Get()) Then
					Cancel = True;
				EndIf;
			EndIf;
		EndIf;
		
		CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
		CurrentObject.StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
		
	ElsIf CurrentObject.PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup Then
		
		IdentifiersOfBasicTypeOfPrices = New Map();
		
		If UsePriceGroups Then
			
			For Each TSRow In CurrentObject.PriceGroups Do
				IdOfBasePriceType = Catalogs.TypesOfPrices.FindPriceTypeId(IdentifiersOfBasicTypeOfPrices, TSRow.BasicPriceType);
				Catalogs.TypesOfPrices.ExtractBasePricesFromFormula(CurrentObject, AvailableBasicPriceTypes, "["+IdOfBasePriceType+"]", Cancel);
				TSRow.Formula = "[" + IdOfBasePriceType + "]*" + Format(((TSRow.Markup/100)+1),"NDS=.; NZ=0; NG=0");
			EndDo;

			If Cancel Then
				Common.MessageToUser(NStr("vi = 'Trong dạng giá, đã chỉ ra dạng giá ảnh hưởng không chính xác. Hãy kiểm tra công thức hoặc dạng giá cơ bản.';
											|ru = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
											|en = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.'; fa = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
											|it = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
											|pl = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
											|tr = 'Fiyat türünde yanlış bir etkileyen fiyat türü belirtildi. Formülleri veya temel fiyat türünü kontrol edin.'"), Object.Ref,,,Cancel);
			EndIf;
			
		EndIf;
		
		IdOfBasePriceType = Catalogs.TypesOfPrices.FindPriceTypeId(IdentifiersOfBasicTypeOfPrices, CurrentObject.BasicPriceType);
		Catalogs.TypesOfPrices.ExtractBasePricesFromFormula(CurrentObject, AvailableBasicPriceTypes, "["+IdOfBasePriceType+"]", Cancel);
		CurrentObject.Formula = "[" + IdOfBasePriceType + "]*" + Format(((CurrentObject.Markup/100)+1),"NDS=.; NZ=0; NG=0");

		If Cancel Then
			Common.MessageToUser(NStr("vi = 'Trong dạng giá, đã chỉ ra dạng giá ảnh hưởng không chính xác. Hãy kiểm tra công thức hoặc dạng giá cơ bản.';
										|ru = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
										|en = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.'; fa = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
										|it = 'В виде цен указан некорректный влияющий вид цены. Проверьте формулы или базовый вид цены.';
										|pl = 'An incorrect influencing price type is specified in the price type. Check the formulas or basic price type.';
										|tr = 'Fiyat türünde yanlış bir etkileyen fiyat türü belirtildi. Formülleri veya temel fiyat türünü kontrol edin.'"), Object.Ref,,,Cancel);
		EndIf;
		
		If Not ValueIsFilled(Object.DataCompositionSchema) Then
			SchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
			If StorageOfDataCompositionSchema <> Undefined And SchemaStorage.Get() <> Undefined Then
				If Not PriceManagementSystem.CheckDataLayoutScheme(SchemaStorage.Get()) Then
					Cancel = True;
				EndIf;
			EndIf;
		EndIf;
		
		CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
		CurrentObject.StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
		
	ElsIf CurrentObject.PricingMethod = Enums.PriceSettingMethods.Manually Then
		
		If Not ValueIsFilled(Object.DataCompositionSchema) Then
			SchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
			If StorageOfDataCompositionSchema <> Undefined And SchemaStorage.Get() <> Undefined Then
				If Not PriceManagementSystem.CheckDataLayoutScheme(SchemaStorage.Get()) Then
					Cancel = True;
				EndIf;
			EndIf;
		EndIf;
		
		CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
		CurrentObject.StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
		
	ElsIf CurrentObject.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
		Or CurrentObject.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice Then	
		
		CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
	
	
	EndIf;
	
	If Not Catalogs.TypesOfPrices.AllowChangingFormulas(CurrentObject.PricingMethod) Then
		
		CurrentObject.Formula = "";
		If UsePriceGroups Then
			For Each TSRow In CurrentObject.PriceGroups Do
				TSRow.Formula = "";
			EndDo;
		EndIf;
		
	EndIf;
	
	CurrentObject.StorageOfFilterByItemsDataCompositionSettings = StorageOfFilterByItemsDataCompositionSettings;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	If UseSeveralPriceTypes Then
		// Subsystem prohibiting editing of key details of objects	
		ObjectAttributesLock.LockAttributes(ThisForm);
	EndIf;
	
	ConfigureTableRoundingRuleServer(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If UsePriceGroups 
		And Object.PriceGroups.Count() > 0
		And (Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes")
		Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup")) Then
	
		// To calculate prices correctly, there should be no duplicates of price groups and empty rows in the Formula table.
		TableOfPriceGroups = New ValueTable;
		TableOfPriceGroups.Columns.Add("LineNumber",         New TypeDescription("Number"));
		TableOfPriceGroups.Columns.Add("PriceGroup",       New TypeDescription("CatalogRef.PriceGroups"));
		TableOfPriceGroups.Columns.Add("Formula", New TypeDescription("String",,New StringQualifiers(1000)));
		
		For Each TSRow In Object.PriceGroups Do
			FillPropertyValues(TableOfPriceGroups.Add(), TSRow);
		EndDo;
		
		Query = New Query("
			|SELECT
			|	TemporaryTablePriceGroups.LineNumber         AS LineNumber,
			|	TemporaryTablePriceGroups.PriceGroup       AS PriceGroup,
			|	TemporaryTablePriceGroups.Formula AS Formula
			|INTO
			|	TemporaryTablePriceGroups
			|FROM
			|	&TableOfPriceGroups AS TemporaryTablePriceGroups
			|;
			|SELECT
			|	MAX(TemporaryTablePriceGroups.LineNumber)    AS LineNumber,
			|	TemporaryTablePriceGroups.PriceGroup            AS PriceGroup
			|FROM
			|	TemporaryTablePriceGroups AS TemporaryTablePriceGroups
			|WHERE
			|	TemporaryTablePriceGroups.PriceGroup <> VALUE(Catalog.PriceGroups.EmptyRef)
			|GROUP BY
			|	TemporaryTablePriceGroups.PriceGroup
			|HAVING
			|	COUNT (*) > 1
			|ORDER BY
			|	LineNumber ASC
			|;
			|");
			
		Query.SetParameter("TableOfPriceGroups", TableOfPriceGroups);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
		
			ErrorText = NStr("vi = 'Nhóm giá ""%PriceGroup%"" lặp lại';
							|ru = 'Ценовая группа ""%PriceGroup%"" повторяется';
							|en = 'Price group ""%PriceGroup%"" is repeated'; fa = 'Price group ""%PriceGroup%"" is repeated';
							|it = 'Gruppo di prezzi ""%PriceGroup%"" si ripete';
							|pl = 'Grupa cenowa ""%PriceGroup%"" powtarza się';
							|tr = '""%PriceGroup%"" fiyat grubu tekrarlanmaktadır'");
			ErrorText = StrReplace(ErrorText, "%PriceGroup%", Selection.PriceGroup);
			
			Common.MessageToUser(
				ErrorText,
				Object.Ref,
				"ClarificationByPriceGroupPresentation",,
				Cancel);
		
		EndDo;
	
	EndIf;
	
	If Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
		
		ExpectedValueType = New TypeDescription("Number");
		CheckParameters = ProcessingOfFormulas.FormulaValidationParameters();
		CheckParameters.Field = "Object.Formula";
		If Not ProcessingOfFormulas.CheckFormula(Object.Formula, BasicPriceTypesServer(), ExpectedValueType, CheckParameters) Then
			Cancel = True;
		EndIf;
		
		If UsePriceGroups Then
		
			CurIndex__ = 0;
			For Each Formula In Object.PriceGroups Do
				
				ErrorText = NStr("vi = 'Đã phát hiện lỗi trong công thức đối với nhóm giá ""%PriceGroup%""';
								|ru = 'В формуле для ценовой группы ""%PriceGroup%"" обнаружены ошибки';
								|en = 'Errors are detected in a formula for price group ""%PriceGroup%""'; fa = 'Errors are detected in a formula for price group ""%PriceGroup%""';
								|it = 'Nella formula del gruppo di prezzi ""%PriceGroup%"" sono rilevati errori';
								|pl = 'W formule dla grupy cenowej ""%PriceGroup%"" wykryto błędy';
								|tr = '""%PriceGroup%"" fiyat grubuna yönelik formülde hatalar bulundu'");
				ErrorText = StrReplace(ErrorText, "%PriceGroup%", Formula.PriceGroup);
				
				CheckParameters.Field = "Object.Formulae[" + CurIndex__ + "].Formula";
				CheckParameters.ErrorMessage = ErrorText;
				If Not ProcessingOfFormulas.CheckFormula(Formula.Formula, BasicPriceTypesServer(), ExpectedValueType, CheckParameters) Then
					Cancel = True;
				EndIf;
				CurIndex__ = CurIndex__ + 1;
				
			EndDo;
			
		EndIf;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
	
		If Object.Markup < -100 Then
			ErrorText = NStr("vi = 'Đã phát hiện lỗi trong chiết khấu - chiết khấu không thể lớn hơn 100%';
							|ru = 'В скидке для обнаружена ошибка - скидка не может быть больше 100%';
							|en = 'An error is detected in the discount. The discount cannot be more than 100%'; fa = 'An error is detected in the discount. The discount cannot be more than 100%';
							|it = 'В скидке для обнаружена ошибка - скидка не может быть больше 100%';
							|pl = 'An error is detected in the discount. The discount cannot be more than 100%';
							|tr = 'İndirimde hata bulundu; indirim 100%''den fazla olamaz'");
			
			Common.MessageToUser(
				ErrorText,
				Object.Ref,
				"ModuleMarkUp");
			
			Cancel = True;
		ElsIf Object.Markup = 0 Then
			ErrorText = NStr("vi = 'Chưa điền phần trăm %1';
							|ru = 'Не заполнен процент %1';
							|en = '%1 percentage is not filled in'; fa = '%1 percentage is not filled in';
							|it = '%1 percentage is not filled in';
							|pl = '%1 percentage is not filled in';
							|tr = '%1 yüzdesi doldurulmadı'");
			ErrorText = StrTemplate(ErrorText, ?(ExtraChargeOrDiscount = 1, NStr("vi = 'phụ thu';
																				|ru = 'наценки';
																				|en = 'markup'; fa = 'markup';
																				|it = 'markup';
																				|pl = 'markup';
																				|tr = 'zamlar'"), NStr("vi = 'chiết khấu';
																										|ru = 'скидки';
																										|en = 'discount'; fa = 'discount';
																										|it = 'discount';
																										|pl = 'discount';
																										|tr = 'indirimler'")));
			
			Common.MessageToUser(
				ErrorText,
				Object.Ref,
				"ModuleMarkUp");
			
			Cancel = True;
		EndIf;

		If UsePriceGroups Then
			For Each PriceGroup In Object.PriceGroups Do
				
				ErrorText = NStr("vi = 'Đã phát hiện lỗi trong chiết khấu đối với nhóm giá ""%PriceGroup%"" - chiết khấu không thể lớn hơn 100%';
								|ru = 'В скидке для ценовой группы ""%PriceGroup%"" обнаружены ошибки - скидка не может быть больше 100%';
								|en = 'Errors are detected in the discount for the ""%PriceGroup%"" price group. The discount cannot be more than 100%'; fa = 'Errors are detected in the discount for the ""%PriceGroup%"" price group. The discount cannot be more than 100%';
								|it = 'В скидке для ценовой группы ""%PriceGroup%"" обнаружены ошибки - скидка не может быть больше 100%';
								|pl = 'Errors are detected in the discount for the ""%PriceGroup%"" price group. The discount cannot be more than 100%';
								|tr = '""%PriceGroup%"" fiyat grubuna yönelik indirimde hatalar bulundu; indirim 100%''den fazla olamaz'");
				ErrorText = StrReplace(ErrorText, "%PriceGroup%", PriceGroup.PriceGroup);
				
				If PriceGroup.Markup < -100 Then
					Common.MessageToUser(
						ErrorText,
						Object.Ref,
						"ClarificationByPriceGroupPresentation");
					Cancel = True;
				EndIf;
				
			EndDo;
		EndIf;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
		Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice") Then
		
		If Object.Markup = 0 Then
			ErrorText = NStr("vi = 'Chưa điền phần trăm %1';
							|ru = 'Не заполнен процент %1';
							|en = '%1 percentage is not filled in'; fa = '%1 percentage is not filled in';
							|it = '%1 percentage is not filled in';
							|pl = '%1 percentage is not filled in';
							|tr = '%1 yüzdesi doldurulmadı'");
			ErrorText = StrTemplate(ErrorText, ?(ExtraChargeOrDiscount = 1, NStr("vi = 'phụ thu';
																				|ru = 'наценки';
																				|en = 'markup'; fa = 'markup';
																				|it = 'markup';
																				|pl = 'markup';
																				|tr = 'zamlar'"), NStr("vi = 'chiết khấu';
																										|ru = 'скидки';
																										|en = 'discount'; fa = 'discount';
																										|it = 'discount';
																										|pl = 'discount';
																										|tr = 'indirimler'")));
			
			Common.MessageToUser(
				ErrorText,
				Object.Ref,
				"ModuleMarkUp");
			
			Cancel = True; 
		EndIf;
		
	
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	Notify("ChangingTypeOfPrices", Object.Ref, FormOwner);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);

EndProcedure

&AtClient
Procedure TheLinkerSettingsSelectionItemPresentationProcessingOfNavigationLinks(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	EditDataCompositionSchemaClient(True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	If EventName = "Write_ConstantsSet" Then
		If Source =	"UseStoreFormats" 
			Or Source =	"UseSeveralWarehouses"
			Or Source =	"UsePartnersAndCounterparties"
			Or Source =	"ToUseTermsOfSales" Then
			
			CreateListToSelectPriceTypeAssignments();
			
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	OwnerOfIndividualTypeOfPricesWhenServerChanges(ValueSelected);
	
	UpdateSuggestedIDValue();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WriteCatalog(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PricingMethodOnChange(Item)
	
	SetUpFormItemsVisibility(ThisForm);
	
	InitializeSettingsAccordingToMethodOfSettingPrice(True);
	
	MethodForSettingPricesWhenChangesOccurOnServer();
	
	PreviousPricingMethod = Object.PricingMethod;
	
	UpdatePresentationToClarifyValueOfMarkUpDiscount();

	UpdateSuggestedIDValue();

EndProcedure

&AtClient
Procedure ParametersOfTheCalculationTypeOnChange(Item)
	
	WriteValuesOfAdditionalParametersOfVSKD(Item.Name);
	
EndProcedure

&AtClient
Procedure DepthOfDataAnalysisOnChange(Item)

	WriteValuesOfAdditionalParametersOfVSKD(Item.Name);
	
EndProcedure

&AtClient
Procedure ParametersOfTheCalculationTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SetPriceDuringGenerationOnChange(Item)
	SetUpFormItemsVisibility(ThisForm);
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	UpdateSuggestedIDValue();
	
EndProcedure

&AtClient
Procedure PriceCurrencyOnChange(Item)
	
	ConfigureTableRoundingRule();
	ConfigureAvailabilityOfFormElements(ThisForm);
	
EndProcedure

&AtClient
Procedure TypeOfPriceTypeWhenChanging(Item)
	
	UpdateDataOnOwnerOfIndividualPriceType(True);
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);	
	AdjustVisibilityAvailabilityOfItemsWhenChangingTypeOfPriceView(ThisForm);
	
EndProcedure

&AtClient
Procedure OwnerOfAnIndividualPriceTypePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ChangePriceTypeAssignment" Then
		
		If Not ValueIsFilled(Object.Ref) Then
		
			QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
			|Chỉ có thể chọn đối tượng chủ của bảng giá riêng sau khi ghi lại phần tử.
			|Ghi lại phần tử?';
			|ru = 'Данные еще не записаны.
			|Выбор владельца индивидуального прайс-листа возможно только после записи элемента.
			|Записать элемент?';
			|en = 'The data has not been written yet.
			|Selecting the owner of the individual price list is only possible after the element has been saved.
			|Save the element?'; fa = 'The data has not been written yet.
			|Selecting the owner of the individual price list is only possible after the element has been saved.
			|Save the element?';
			|it = 'Dati ancora non registrati. 
			|La selezione del proprietario del listino prezzi individuale è possibile solo dopo la registrazione dell''elemento. 
			|Registrare elemento?';
			|pl = 'Dane jeszcze nie są zapisane.
			|Wybór właściciela indywidualnego cennika możliwe jest tylko po zapisywaniu elementu.
			|Zapisać element?';
			|tr = 'Veriler henüz kaydedilmedi.
			|Özelleştirilmiş fiyat listesinin sahibinin seçilmesi sadece öğe kaydından sonra mümkündür.
			|Öğe kaydedilsin mi?'");
			
			ShowQueryBox(New CallbackDescription("WritingCompletionElement", ThisObject), QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
		
		OwnerOfAnIndividualPriceTypePresentationURLProcessingCompletion();
		
	ElsIf FormattedStringURL = "DiscoverOwnerOfIndividualPriceType" Then
			 	
		ShowValue(Undefined, OwnerOfAnIndividualPriceType);
		
	EndIf;
EndProcedure

&AtClient
Procedure WritingCompletionElement(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    Try
        ItemRecorded = Write();
    Except
        Return;
    EndTry;
    
    If Not ItemRecorded Then
        Return;
    EndIf;
    
	OwnerOfAnIndividualPriceTypePresentationURLProcessingCompletion();

EndProcedure

&AtClient
Procedure OwnerOfAnIndividualPriceTypePresentationURLProcessingCompletion() Export
	
	ClearMessages();
	
	StructureFilter = New Structure;
	FormOpenParameters = New Structure("Filter", StructureFilter);
	
	If Object.Purpose = PredefinedValue("Enum.PriceTypesAssignment.SpecialForWarehouse") Then
		ChoiceFormName = "Catalog.Warehouses.ChoiceForm";
		FormOpenParameters.Insert("SelectWarehouseGroup", False);
		StructureFilter.Insert("WarehouseStore", PredefinedValue("Enum.TypesOfWarehouses.RetailStore"));
	ElsIf Object.Purpose = PredefinedValue("Enum.PriceTypesAssignment.SpecialForStoreFormat") Then
		ChoiceFormName = "Catalog.StoreFormats.ChoiceForm";
	ElsIf Object.Purpose = PredefinedValue("Enum.PriceTypesAssignment.SpecialForPartner") Then
		ChoiceFormName = "Catalog.Partners.ChoiceForm";
	ElsIf Object.Purpose = PredefinedValue("Enum.PriceTypesAssignment.SpecialForTermsOfSales") Then
		ChoiceFormName = "Catalog.TermsOfSale.ChoiceForm";
	EndIf;
	
	OpenForm(
		ChoiceFormName,
		FormOpenParameters,
		ThisForm);
	
EndProcedure

&AtServer
Procedure OwnerOfIndividualTypeOfPricesWhenServerChanges(ValueSelected)
	
	ChangeOfIPLMade 	= False;
	DetailsForInstallingIPL 		= Undefined;
	DataForRemovingIPL 		= Undefined;
	
	Block = New DataLock;
	
	// checking the possibility and installing the IPL for the object
	DetailsForInstallingIPL = CatalogForIPL(ValueSelected);	
	
	If Not DetailsForInstallingIPL = Undefined Then
		LockItem = Block.Add(DetailsForInstallingIPL.DataToBlock);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Ref", DetailsForInstallingIPL.Ref);
	EndIf;
	
	If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
		DataForRemovingIPL = CatalogForIPL(OwnerOfAnIndividualPriceType);		
		If Not DataForRemovingIPL = Undefined Then
			LockItem = Block.Add(DataForRemovingIPL.DataToBlock);
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Ref", DataForRemovingIPL.Ref);		
		EndIf;
	EndIf;	
	
	ChangeOfIPLMade = False;
	If Block.Count() Then
		BeginTransaction();
		Try	
			Block.Lock();
			
			If Not DataForRemovingIPL = Undefined Then
				ChangeOfIPLMade = DataForRemovingIPL.CatalogOfChangesInIPL.DeleteIPL(DataForRemovingIPL.Ref);
			EndIf;
			If Not DetailsForInstallingIPL = Undefined Then
				ChangeOfIPLMade = DetailsForInstallingIPL.CatalogOfChangesInIPL.InstallIPL(DetailsForInstallingIPL.Ref, Object.Ref);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorPresentation = BriefErrorDescription(ErrorInfo());
			Common.MessageToUser(ErrorPresentation, ,"OwnerOfAnIndividualPriceTypePresentation");
		EndTry;
	EndIf;
		
	If ChangeOfIPLMade Then
		Modified = True;
		OwnerOfAnIndividualPriceType = ValueSelected;
		
		UpdateOwnerIndividualViewPricePresentation();
		
		If Not ValueIsFilled(Object.Description) Then
			Description = NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'");
			Description = StrReplace(Description, "%1", String(OwnerOfAnIndividualPriceType));
			
			Object.Description = Description;
		EndIf;
	EndIf;	
	
EndProcedure

&AtClient
Procedure RoundingPrecisionOnChange(Item)
	
	RoundingAccuracyWhenChangedOnClient();
	
EndProcedure

&AtClient
Procedure UseAdvancedRoundingSettingOnChange(Item)
	
	If Not UseAdvancedRoundingSetting Then
		Object.PriceRoundingRules.Clear();
		If Object.Round Then
			NewRow = Object.PriceRoundingRules.Add();
			NewRow.RoundingPrecision = Object.RoundingPrecision;
		EndIf;
	EndIf;
	
	ConfigureTableRoundingRuleServer(ThisForm);
	AdjustVisibilityAvailabilityOfRoundingSettings(ThisForm);
	UpdatePresentationRefinementOfRoundingSettings();
	
EndProcedure

&AtClient
Procedure UseTriggerThresholdsOnChange(Item)
	
	UseTriggerThresholdsWhenChangingOnClient();
	AdjustVisibilityAvailabilityOfThresholdSettings(ThisForm);
	
EndProcedure

&AtClient
Procedure RoundOnChange(Item)
	
	AdjustVisibilityAvailabilityOfRoundingSettings(ThisForm);
	
	If Object.Round Then
		Object.RoundingPrecision = ?(Object.RoundingPrecision = 0, 1, Object.RoundingPrecision);
	Else			
		Object.RoundingPrecision = 0;
	EndIf;
	
	RoundingAccuracyWhenChangedOnClient();
	
EndProcedure

&AtServer
Procedure SetValueToUseServerWhenSelling()
	Object.UseWhileSellingToCustomers = Object.UseForWholesaleToCustomers Or Object.UseForRetailSalesToCustomers;		
EndProcedure

&AtServer
Procedure SetValueAuxiliaryPriceServer()
	If Object.Purpose <> Enums.PriceTypesAssignment.Shared
		Or Object.UseForWholesaleToCustomers
		Or Object.UseForRetailSalesToCustomers
		Or Object.UseForIssuingProductsWorksAndServicesAtFixedCost 
		Or Object.UseForIntercompanySales 
		Or Object.UseWhileTransferringProductsToMaterialProvider	Then

		Object.AuxiliaryPrice = False;		
	EndIf;	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityAuxiliaryPrice(Form)
	If Form.Object.Purpose <> PredefinedValue("Enum.PriceTypesAssignment.Shared")
		Or Form.Object.UseForWholesaleToCustomers
		Or Form.Object.UseForRetailSalesToCustomers
		Or Form.Object.UseForIssuingProductsWorksAndServicesAtFixedCost 
		Or Form.Object.UseForIntercompanySales 
		Or Form.Object.UseWhileTransferringProductsToMaterialProvider Then

		Form.Items.AuxiliaryPrice.Enabled = False;
		
	Else
		Form.Items.AuxiliaryPrice.Enabled = True;
		
	EndIf;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfVATRates(Form, OpeningForm = False)
	
	If Not Form.UsePriceManagementSystem25 Then
		Return;
	EndIf;
	
	NotSpecifiedVATRates = PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates");
	If	Not Form.Object.UseForRetailSalesToCustomers
			And (Form.Object.UseForWholesaleToCustomers
			Or Form.Object.UseForIntercompanySales) Then

		Form.Items.OptionForSpecifyingVATRates.Enabled = True;
		Form.Items.OptionForSpecifyingVATRates.AutoMarkIncomplete = True;
		
		If Form.UseMultiCountryAccounting Then
			
			If Form.Object.OptionForSpecifyingVATRates = NotSpecifiedVATRates Then
				Form.Items.Country.Enabled = False;
				Form.Items.Country.AutoMarkIncomplete = False;
			Else
				Form.Items.Country.Enabled = True;
				Form.Items.Country.AutoMarkIncomplete = True;
			EndIf;
			
		EndIf;
	
		If Form.Object.OptionForSpecifyingVATRates = PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems") Then
			Form.Items.VATRate.Enabled = True;
			Form.Items.VATRate.AutoMarkIncomplete = True;
		Else
			Form.Items.VATRate.AutoMarkIncomplete = False;
		EndIf;
		
	Else
		
		If Not OpeningForm And Not Form.Object.OptionForSpecifyingVATRates = NotSpecifiedVATRates Then
			Form.Object.OptionForSpecifyingVATRates = NotSpecifiedVATRates;
			Form.Items.Country.Visible = False;
			Form.Items.VATRate.Visible = False;
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Form.Items, "OptionForSpecifyingVATRates, Country, VATRate", "Enabled", False);
			
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Form.Items, "OptionForSpecifyingVATRates, Country, VATRate", "AutoMarkIncomplete", False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseWhenSellingWhenChanging(Item)
	SetValueToUseServerWhenSelling();
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);
	SetAvailabilityOfVATRates(ThisObject);
EndProcedure

&AtClient
Procedure UseForRetailSalesToCustomersOnChange(Item)
	SetValueToUseServerWhenSelling();
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);
	SetAvailabilityOfVATRates(ThisObject);
EndProcedure

&AtClient
Procedure UseWhenSellingBetweenOrganizationsOnChange(Item)
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);
	SetAvailabilityOfVATRates(ThisObject);
EndProcedure

&AtClient
Procedure UseWhileTransferringProductsToMaterialProviderOnChange(Item)
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);
	SetAvailabilityOfVATRates(ThisObject);
EndProcedure

&AtClient
Procedure UseForIssuingProductsWorksAndServicesAtFixedCostOnChange(Item)
	SetValueAuxiliaryPriceServer();
	SetAvailabilityAuxiliaryPrice(ThisForm);
	SetAvailabilityOfVATRates(ThisObject);
EndProcedure

&AtClient
Procedure RoundOffOptionOnChange(Item)
	ConfigureTableRoundingRule();
EndProcedure

&AtClient
Procedure PricingMethodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TypeOfPriceTypeCleaning(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ParametersOfPriceSettingMethodOnChange(Item)

	ParametersOfPriceSettingMethodCustomType = Undefined;
	
	If TypeOf(ParametersOfPriceSettingMethodAddOn) <> Type("ValueList")
		Or ParametersOfPriceSettingMethodAddOn.FindByValue(ParametersOfPriceSettingMethod) = Undefined Then
		Items.ParametersOfPriceSettingMethodCustomType.Visible = False;
		Items.ParametersOfPriceSettingMethodCustomType.AutoMarkIncomplete = False;
	Else
		Items.ParametersOfPriceSettingMethodCustomType.Visible = True;
		Items.ParametersOfPriceSettingMethodCustomType.AutoMarkIncomplete = True;
		
		FillInItemSelectionListOnServer("ParametersOfPriceSettingMethodCustomType");
	EndIf;
	

	Modified = True;
	
EndProcedure

&AtClient
Procedure ParametersOfPriceSettingMethodCustomTypeOnChange(Item)

	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ValidityStatusOnChange(Item)
	SetUpFormItemsVisibility(ThisObject);
EndProcedure

&AtClient
Procedure OptionForSpecifyingVATRatesOnChange(Item)
	
	AdjustVisibilityOfVATRatesElements(ThisObject, False);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditDataCompositionSchema(Command)
	
	EditDataCompositionSchemaClient();
	
EndProcedure

&AtClient
Procedure EditDataCompositionSchemaClient(EditingProductSelectionSettings = False)
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh sơ đồ dàn dựng dữ liệu đối với dạng giá ""%1""';
													|ru = 'Настройка схемы компоновки данных для вида цены ""%1""';
													|en = 'Setting of data composition schema for price type ""%1""'; fa = 'Setting of data composition schema for price type ""%1""';
													|it = 'Impostazione dello schema di composizione dei dati per il tipo di prezzo ""%1""';
													|pl = 'Ustawienia schematu układu danych dla rodzaju ceny ""%1""';
													|tr = '""%1"" fiyat türü için veri inşa edilme şeması ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", Object.Description);
	
	Addresses = GetAddressesOfDataLayoutSchemeInTemporaryStorage(EditingProductSelectionSettings);
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	
	LimitSetting = Not Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseData");
	
	FormParameters.Insert("DoNotConfigureSelection", 						False);
	FormParameters.Insert("DoNotConfigureSettings", 					EditingProductSelectionSettings);
	FormParameters.Insert("NotEditDataCompositionSchema", 	LimitSetting);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", 	LimitSetting);
		
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	
	FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", "PriceManagementSystem.CheckingCorrectnessOfPriceTypeScheme");
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditDataCompositionSchemaCompletion",
			ThisObject,
			New Structure("Addresses, EditSchemeByProductName", Addresses, EditingProductSelectionSettings)),
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export

	Addresses = AdditionalParameters.Addresses;
	EditingProductSelectionSettings = AdditionalParameters.EditSchemeByProductName; 
	AddressOfComposerConfigurationStore = Result;
	
	If ValueIsFilled(AddressOfComposerConfigurationStore) Then
		If EditingProductSelectionSettings Then
			
			ApplyChangesToProductSelectionSettings(AddressOfComposerConfigurationStore);
			
			UpdateProductSelectionPresentation();
			
		Else
			
			ApplyChangesToDataLayoutScheme(Addresses.DataCompositionSchema, AddressOfComposerConfigurationStore, Addresses.DataLayoutDiagramControl);
			
			UpdateDataLayoutPresentation();
			
			SetAdditionalParameterValues();

		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FormulasConstructor(Command)
	
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersOfPriceEditingForm(Object.Formula), Items.Formula,,,, New CallbackDescription("FormulasConstructorCompletion", ThisObject), FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure FormulasConstructorCompletion(Result, AdditionalParameters) Export
	
	EditResult = Result;
	
	If EditResult <> Undefined Then
		Object.Formula = EditResult;
	EndIf;

EndProcedure

&AtClient
Procedure CheckFormulas(Command)
	
	ClearMessages();
	
	ExpectedValueType = New TypeDescription("Number");
	CheckParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
	CheckParameters.Field = "Object.Formula";
	
	ErrorsDetected = False;
	If ValueIsFilled(Object.Formula) Then
		If Not ProcessingOfFormulasClient.CheckFormula(Object.Formula, BasicPriceTypes(), ExpectedValueType, CheckParameters) Then
			ErrorsDetected = True;
		EndIf;
	EndIf;
	
	For Each Formula In Object.PriceGroups Do
		ElementIndex = Object.PriceGroups.IndexOf(Formula);
		CheckParameters.Field = "Object.PriceGroups[" + ElementIndex + "].Formula";
		If Not ProcessingOfFormulasClient.CheckFormula(Formula.Formula, BasicPriceTypes(), ExpectedValueType, CheckParameters) Then
			ErrorsDetected = True;
		EndIf;
	EndDo;
	
	If Not ErrorsDetected Then
		ShowUserNotification(
			NStr("vi = 'Không phát hiện lỗi trong công thức';
				|ru = 'В формулах ошибок не обнаружено';
				|en = 'Formulas contain no errors'; fa = 'Formulas contain no errors';
				|it = 'Nessun errore trovato nella formula';
				|pl = 'W formułach nie wykryto błędów';
				|tr = 'Formüllerde hata bulunamadı'"),
			,
			,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure RoundingConstructor(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("RoundingPrecision", Object.RoundingPrecision);
	FormParameters.Insert("RoundOffOption", Object.RoundOffOption);
	
	OpenForm("Catalog.TypesOfPrices.Form.SmartRoundingConstructorForm", 
		FormParameters,,,,,
		New CallbackDescription("RoundingConstructorCompletion",
			ThisObject,
			),
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure RoundingConstructorCompletion(Result, AdditionalParameters) Export
    
    EditResult = Result;
    
    If EditResult <> Undefined Then
        Object.RoundingPrecision = EditResult.RoundingPrecision;
        Object.RoundOffOption = EditResult.RoundOffOption;
    EndIf;

EndProcedure

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure TheCircuitLayoutDataRepresentationOfTheProcessingOfTheNavigationLinks(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	EditDataCompositionSchemaClient();
	
EndProcedure

&AtClient
Procedure ClarificationByPriceGroupPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;

	TypeOfCall = GetTypeOfCall(Item.Name);

	ConfigureConstraints(TypeOfCall);

EndProcedure

&AtClient
Procedure RefinementOfRoundingSettingsPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	TypeOfCall = GetTypeOfCall(Item.Name);		

	ConfigureConstraints(TypeOfCall);

EndProcedure

&AtClient
Procedure RefinementOfResponseThresholdsPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	TypeOfCall = GetTypeOfCall(Item.Name);

	ConfigureConstraints(TypeOfCall);

EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdatePresentationToClarifyValueOfMarkUpDiscount()
	
	If Object.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
		If Object.PriceGroups.Count() = 0 Then
			ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Làm rõ công thức theo nhóm giá';
																			|ru = 'Уточнить формулы по ценовым группам';
																			|en = 'Specify formulas by price groups'; fa = 'Specify formulas by price groups';
																			|it = 'Specificare formule per gruppi di prezzo';
																			|pl = 'Uściślij formuły wg grup cenowych';
																			|tr = 'Fiyat gruplarına göre formülleri netleştir'"),,,,"Change");
		Else
			ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Có làm rõ công thức theo nhóm giá';
																			|ru = 'Есть уточнения формул по ценовым группам';
																			|en = 'There are specifications of formulas by price groups'; fa = 'There are specifications of formulas by price groups';
																			|it = 'Vi sono indicazioni delle formule per gruppi di prezzo';
																			|pl = 'Są uściślenia formuł wg grup cenowych';
																			|tr = 'Fiyat gruplarına göre formül iyileştirmesi mevcut'"),,,,"Change");
		EndIf;
	Else	
		If Object.PriceGroups.Count() = 0 Then
			ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Làm rõ phụ thu theo nhóm giá';
																			|ru = 'Уточнить наценки по ценовым группам';
																			|en = 'Specify markups by price groups'; fa = 'Specify markups by price groups';
																			|it = 'Specificare maggiorazione per gruppi di prezzo';
																			|pl = 'Uściślij marże wg grup cenowych';
																			|tr = 'Fiyat gruplarına göre zamları netleştir'"),,,,"Change");
		Else
			ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Có làm rõ phụ thu theo nhóm giá';
																			|ru = 'Есть уточнения наценок по ценовым группам';
																			|en = 'There are specifications of markups by price groups'; fa = 'There are specifications of markups by price groups';
																			|it = 'Vi sono indicazioni delle maggiorazioni per gruppi di prezzo';
																			|pl = 'Są uściślenie marż wg grup cenowych';
																			|tr = 'Fiyat gruplarına göre zam iyileştirmesi mevcut'"),,,,"Change");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCurrencyRefinementPresentation()
	
	If Object.Currencies.Count() = 0 Then
		SpecifyingCurrenciesByPriceGroupPresentation = New FormattedString(NStr("vi = 'Làm rõ tiền tệ theo nhóm giá';
																				|ru = 'Уточнить валюты по ценовым группам';
																				|en = 'Specify currencies by price groups'; fa = 'تعیین ارزها بر اساس گروه‌های قیمت';
																				|it = 'Specificare valuta per gruppi di prezzo';
																				|pl = 'Uściślij waluty wg grup cenowych';
																				|tr = 'Fiyat gruplarına göre para birimlerini netleştir'"),,,,"Change");
	Else
		SpecifyingCurrenciesByPriceGroupPresentation = New FormattedString(NStr("vi = 'Làm rõ tiền tệ theo nhóm giá';
																				|ru = 'Есть уточнения валют по ценовым группам';
																				|en = 'There are specifications of currencies by price groups'; fa = 'There are specifications of currencies by price groups';
																				|it = 'Vi sono indicazioni di valuta per gruppi di prezzo';
																				|pl = 'Są uściślenia walut wg grup cenowych';
																				|tr = 'Fiyat gruplarına göre para birimi iyileştirmesi mevcut'"),,,,"Change");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationUpdateTriggerThresholds()
	
	If Object.Thresholds.Count() = 0 Then
		RefinementOfResponseThresholdsPresentation = New FormattedString(NStr("vi = 'Làm rõ ngưỡng kích hoạt theo nhóm giá';
																				|ru = 'Уточнить пороги срабатывания по ценовым группам';
																				|en = 'Specify trigger thresholds by price groups'; fa = 'Specify trigger thresholds by price groups';
																				|it = 'Specificare soglie di innesco per gruppi di prezzo';
																				|pl = 'Uściślij progi zadziałania wg grup cenowych';
																				|tr = 'Fiyat gruplarına göre sapma yüzdesini netileştir'"),,,,"Change");
	Else
		RefinementOfResponseThresholdsPresentation = New FormattedString(NStr("vi = 'Làm rõ ngưỡng kích hoạt theo nhóm giá';
																				|ru = 'Есть уточнения порогов срабатывания по ценовым группам';
																				|en = 'There are trigger threshold specifications by price groups'; fa = 'There are trigger threshold specifications by price groups';
																				|it = 'Vi sono indicazioni di soglie di innesco per gruppi di prezzo';
																				|pl = 'Są uściślenia progów zadziałania wg grup cenowych';
																				|tr = 'Fiyat gruplarına göre tetik eşiklerinin iyileştirmesi mevcut'"),,,,"Change");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationRefinementOfRoundingSettings()
	
	If Object.PriceRoundingRules.Count() = 0 Then
		RefinementOfRoundingSettingsPresentation = New FormattedString(NStr("vi = 'Tùy chỉnh làm tròn đơn giá theo khoảng';
																			|ru = 'Настроить округление цен по диапазонам';
																			|en = 'Configure price rounding by ranges'; fa = 'Configure price rounding by ranges';
																			|it = 'Impostare arrotondamento dei prezzi per intervalli';
																			|pl = 'Ustaw zaokrąglenie cen wg zakresów';
																			|tr = 'Aralıklara göre fiyat yuvarlamasını ayarla'"),,,,"Change");
	Else
		
		If Object.PriceRoundingRules.Count() > 1 
			Or (Object.PriceRoundingRules.Count() = 1  And Object.PriceRoundingRules[0].RoundingPrecision <> 0) Then
			DecipheringPriceRanges = NStr("vi = '%1%2';
											|ru = '%1%2';
											|en = '%1%2'; fa = '%1%2';
											|it = '%1%2';
											|pl = '%1%2';
											|tr = '%1%2'");
			FormatString = "NFD=2; NGS=' '; NZ=; NG=0";
			
			RulesArray = New Array();
			
			For Each Rule In Object.PriceRoundingRules Do
				
				If Rule.RoundingPrecision = 0 Then
					StringForSubstitution = NStr("vi = 'không làm tròn';
												|ru = 'не округлять';
												|en = 'do not round off'; fa = 'do not round off';
												|it = 'non arrotondare';
												|pl = 'nie zaokrąglaj';
												|tr = 'yuvarlama'");
				Else
					StringForSubstitution = NStr("vi = 'với độ chính xác';
												|ru = 'с точностью';
												|en = 'to'; fa = 'تا';
												|it = 'con precisione';
												|pl = 'z dokładnością';
												|tr = 'şu duyarlılıkla'") + " " + Format(Rule.RoundingPrecision, FormatString);
				EndIf;
				
				RulesArray.Add(StrTemplate(NStr("vi = '%1 %2';
												|ru = '%1 %2';
												|en = '%1 %2'; fa = '%1 %2';
												|it = '%1 %2';
												|pl = '%1 %2';
												|tr = '%1 %2'"), Rule.PriceRange, StringForSubstitution));
				
			EndDo;

			
			DecipheringPriceRanges = StringFunctionsClientServer.SubstituteParametersToString(DecipheringPriceRanges,
				StrConcat(RulesArray, "; "),
				" ");
		Else

			DecipheringPriceRanges = NStr("vi = 'Tùy chỉnh làm tròn đơn giá theo khoảng';
											|ru = 'Настроить округление цен по диапазонам';
											|en = 'Configure price rounding by ranges'; fa = 'Configure price rounding by ranges';
											|it = 'Impostare arrotondamento dei prezzi per intervalli';
											|pl = 'Ustaw zaokrąglenie cen wg zakresów';
											|tr = 'Aralıklara göre fiyat yuvarlamasını ayarla'");
					
		EndIf;
				
		RefinementOfRoundingSettingsPresentation = New FormattedString(DecipheringPriceRanges,,,,"Change");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateProductSelectionPresentation()
	
	If SettingsComposerFilterByProducts.Settings.Filter.Items.Count() > 0
		And StrLen(TrimAll(String(SettingsComposerFilterByProducts.Settings.Filter))) > 0 Then
		SettingsComposerFilterByProductsPresentation = New FormattedString(NStr("vi = 'Mặt hàng theo bộ lọc:';
																				|ru = 'Номенклатуру по отбору:';
																				|en = 'Items by filter:'; fa = 'Items by filter:';
																				|it = 'Articoli secondo la selezione:';
																				|pl = 'Produkt wg wyboru:';
																				|tr = 'Filtre kapsamındaki öğeyi:'")
		                           + " " + String(SettingsComposerFilterByProducts.Settings.Filter),,,,"Change");
		
		Object.LimitItemFilter = True;
	Else
		SettingsComposerFilterByProductsPresentation = New FormattedString(NStr("vi = 'toàn bộ mặt hàng';
																				|ru = 'всю номенклатуру';
																				|en = 'All items'; fa = 'همه اقلام';
																				|it = 'tutta la nomenclatura';
																				|pl = 'wszystkie pozycje';
																				|tr = 'tüm öğe için'"),,,,"Change");
		
		Object.LimitItemFilter = False;     
		Object.DisablePriceEditingOutsideFilter = False;
	EndIf;
	
	Items.DisablePriceEditingOutsideFilter.ReadOnly	= Not Object.LimitItemFilter Or Not Items.FilterPresentation.Enabled;
	
EndProcedure

&AtServer
Procedure UpdateDataLayoutPresentation()
	
	If SettingsComposer.Settings.Filter.Items.Count() > 0
		And StrLen(TrimAll(String(SettingsComposer.Settings.Filter))) > 0 Then
		SettingsComposerPresentation = New FormattedString(NStr("vi = 'Hạn chế bổ sung bộ lọc theo:';
																|ru = 'Дополнительно ограничивать отбор по:';
																|en = 'Additionally limit filter by:'; fa = 'Additionally limit filter by:';
																|it = 'Limitare ulteriormente il filtro per:';
																|pl = 'Dodatkowo ograniczaj filtr wg:';
																|tr = 'Ek olarak filtreyi şuna göre kısıtla:'")
		                           + " " + String(SettingsComposer.Settings.Filter),,,,"Change");		
	Else
		SettingsComposerPresentation = New FormattedString(NStr("vi = 'Xác định tùy chỉnh bổ sung';
																|ru = 'Уточнить дополнительные настройки';
																|en = 'Specify additional settings'; fa = 'Specify additional settings';
																|it = 'Specificare impostazioni aggiuntive';
																|pl = 'Uściślij ustawienia dodatkowe';
																|tr = 'Ek ayarları netleştir'"),,,,"Change");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUseResponseThresholdsCheckbox()

	UseTriggerThresholds = (Object.ThresholdOnPriceDecreaseBy Or Object.ThresholdOnPriceIncreaseFor);
	
EndProcedure
	
&AtServer
Procedure UpdateDataOnOwnerOfIndividualPriceType(ChangeData = False)
	
	If Not UsePriceManagementSystem25 Then
		
		Items.PriceTypeViewGroup.Visible = False;
		Return;
		
	EndIf;
	
	If Object.Purpose = Enums.PriceTypesAssignment.Shared Or Not ValueIsFilled(Object.Purpose) Then
		If ChangeData Then
			OwnerOfIndividualTypeOfPricesWhenServerChanges(Undefined);
		Else	
			OwnerOfAnIndividualPriceType = Undefined;
		EndIf;
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		ReplacementString = "";
		If Object.Purpose = Enums.PriceTypesAssignment.SpecialForWarehouse Then
			ReplacementString = "Catalog.Warehouses";
		ElsIf Object.Purpose = Enums.PriceTypesAssignment.SpecialForStoreFormat Then 
			ReplacementString = "Catalog.StoreFormats";
		ElsIf Object.Purpose = Enums.PriceTypesAssignment.SpecialForPartner Then 
			ReplacementString = "Catalog.Partners";
		ElsIf Object.Purpose = Enums.PriceTypesAssignment.SpecialForTermsOfSales Then 
			ReplacementString = "Catalog.TermsOfSale";
		EndIf;
		
		RequestTex = "SELECT
		|	OwnerOfAnIndividualPriceType.Ref
		|FROM
		|	&Catalog AS OwnerOfAnIndividualPriceType
		|WHERE
		|	OwnerOfAnIndividualPriceType.SpecialPriceType = &PricesKind";
		
		RequestTex = StrReplace(RequestTex, "&Catalog", ReplacementString);
		
		Query = New Query(RequestTex);
		
		Query.SetParameter("PricesKind", Object.Ref);
		
		SetPrivilegedMode(True);
		Result = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Result.Count() Then
			If ChangeData Then
				OwnerOfIndividualTypeOfPricesWhenServerChanges(Result[0].Ref);
			Else	
				OwnerOfAnIndividualPriceType = Result[0].Ref;
			EndIf;
		Else
			If ChangeData Then
				OwnerOfIndividualTypeOfPricesWhenServerChanges(Undefined);
			Else	
				OwnerOfAnIndividualPriceType = Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	UpdateOwnerIndividualViewPricePresentation();
		
EndProcedure

&AtServer
Procedure UpdateOwnerIndividualViewPricePresentation()
	If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
		ArrayOfTexts = New Array;

		ArrayOfTexts.Add(New FormattedString(String(OwnerOfAnIndividualPriceType),,,,"DiscoverOwnerOfIndividualPriceType"));

		ArrayOfTexts.Add(" (");
		If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
			ArrayOfTexts.Add(New FormattedString(NStr("vi = 'thay đổi';
														|ru = 'изменить';
														|en = 'change'; fa = 'change';
														|it = 'modificare';
														|pl = 'change';
														|tr = 'değiştir'"),,,,"ChangePriceTypeAssignment"));
		Else
			ArrayOfTexts.Add(New FormattedString(NStr("vi = 'chọn';
														|ru = 'выбрать';
														|en = 'select'; fa = 'select';
														|it = 'selezionare';
														|pl = 'select';
														|tr = 'seç'"),,,,"ChangePriceTypeAssignment"));
		EndIf;
		ArrayOfTexts.Add(")");
		
	Else
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'chọn';
													|ru = 'выбрать';
													|en = 'select'; fa = 'select';
													|it = 'selezionare';
													|pl = 'select';
													|tr = 'seç'"),,,,"ChangePriceTypeAssignment"));
	EndIf;
	
	OwnerOfAnIndividualPriceTypePresentation = New FormattedString(ArrayOfTexts);
EndProcedure

&AtClient
Procedure ConfigureConstraints(TypeOfCall)
	
	AddressInStorage = PlaceRowsOfTablePartInStorage(TypeOfCall);
	
	AdditionalParameters = New Structure();
	
	If TypeOfCall = "ClarificationByPriceGroups_CalculateByFormulasFromOtherTypesOfPrices" Then
		 
		AdditionalParameters.Insert("OperatorsTreeStorageAddress",	OperatorsTreeStorageAddress); 
		AdditionalParameters.Insert("AddressOfTheStorageOfBasicTypesOfPrices",	PutBasePriceViewsInStorage()); 
	
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		
		AdditionalParameters.Insert("PriceCurrency",			Object.PriceCurrency); 
		AdditionalParameters.Insert("RoundOffOption",	Object.RoundOffOption); 
		AdditionalParameters.Insert("RoundingPrecision",	Object.RoundingPrecision); 
		
	EndIf;
	
	ParametersStructure = New Structure("AddressInStorage, TypeOfCall, AdditionalParameters", AddressInStorage, TypeOfCall, AdditionalParameters);
	NotificationAfterClarification = New CallbackDescription("ConfiguringConstraintsEnd", ThisObject);
	
	OpenForm("CommonForm.SettingsFormOfPriceGroupsSpecification", ParametersStructure,ThisForm,,,, NotificationAfterClarification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ConfiguringConstraintsEnd(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		FillInConstraintsSettings(Result);
		
		Modified = True;
	EndIf;

EndProcedure

// Fills in the callout settings
// 
// Parameters:
// 	Var_Parameters - Structure
&AtServer 
Procedure FillInConstraintsSettings(Var_Parameters)
	
	TypeOfCall = Var_Parameters.TypeOfCall;
	AdditionalParameters = Var_Parameters.AdditionalParameters;
	
	If AdditionalParameters.Count() Then
		FillPropertyValues(Object, AdditionalParameters);
	EndIf;
	
	TransmittedTable = GetFromTempStorage(Var_Parameters.AddressInStorage);	

	If StrStartsWith(TypeOfCall, "ClarificationByPriceGroup") Then
		
		CurrentTable = Object.PriceGroups;
		ImportTabularSection(TransmittedTable, CurrentTable);

		UpdatePresentationToClarifyValueOfMarkUpDiscount();
		
	ElsIf TypeOfCall = "SpecifyingCurrenciesByPriceGroup" Then
		 
		CurrentTable = Object.Currencies;
		ImportTabularSection(TransmittedTable, CurrentTable);

		UpdateCurrencyRefinementPresentation();
		
	ElsIf TypeOfCall = "RefinementOfResponseThresholds" Then
		 
		CurrentTable = Object.Thresholds;
		ImportTabularSection(TransmittedTable, CurrentTable);
		
		UpdatePresentationUpdateTriggerThresholds();
		
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		 
		CurrentTable = Object.PriceRoundingRules;
		ImportTabularSection(TransmittedTable, CurrentTable);
		
		UpdatePresentationRefinementOfRoundingSettings();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportTabularSection(TransmittedTable, CurrentTable)
	CurrentTable.Clear();
	CurrentTable.Load(TransmittedTable);
EndProcedure

&AtClient
Function GetTypeOfCall(Val Name)
	Result	= "";
	
	If Name = "ClarificationByPriceGroupPresentation" Then
		If Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
		
			Result = "ClarificationByPriceGroup_MarkUpForDifferentTypeOfPrice";
						
		ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
			Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice") 
			Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost") 
			Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
			Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors") Then
				
			Result = "ClarificationByPriceGroup_MarkUpOnReceiptPrice";
			
		ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
			 
			Result = "ClarificationByPriceGroups_CalculateByFormulasFromOtherTypesOfPrices";
			
		EndIf;
	ElsIf Name = "SpecifyingCurrenciesByPriceGroupPresentation" Then
		Result = "SpecifyingCurrenciesByPriceGroup";	
	ElsIf Name = "RefinementOfResponseThresholdsPresentation" Then
		Result = "RefinementOfResponseThresholds";	 	
	ElsIf Name = "RefinementOfRoundingSettingsPresentation" Then 	
		Result = "RefinementOfRoundingSettings";	 	
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function CatalogForIPL(Val ValueSelected)
	DataForChangingIPL = New Structure("DataToBlock, CatalogOfChangesInIPL, Ref");
	
	If ValueSelected = Undefined Or ValueSelected.IsFolder Then
		DataForChangingIPL = Undefined;
	ElsIf TypeOf(ValueSelected) = Type("CatalogRef.Partners") Then
		DataForChangingIPL.DataToBlock = "Catalog.Partners";
		DataForChangingIPL.CatalogOfChangesInIPL = Catalogs.Partners;
		DataForChangingIPL.Ref = ValueSelected;
	ElsIf TypeOf(ValueSelected) = Type("CatalogRef.TermsOfSale") Then
		DataForChangingIPL.DataToBlock = "Catalog.TermsOfSale";
		DataForChangingIPL.CatalogOfChangesInIPL = Catalogs.TermsOfSale;
		DataForChangingIPL.Ref = ValueSelected;
	ElsIf TypeOf(ValueSelected) = Type("CatalogRef.Warehouses") Then
		DataForChangingIPL.DataToBlock = "Catalog.Warehouses";
		DataForChangingIPL.CatalogOfChangesInIPL = Catalogs.Warehouses;
		DataForChangingIPL.Ref = ValueSelected;
	ElsIf TypeOf(ValueSelected) = Type("CatalogRef.StoreFormats") Then
		DataForChangingIPL.DataToBlock = "Catalog.StoreFormats";
		DataForChangingIPL.CatalogOfChangesInIPL = Catalogs.StoreFormats;
		DataForChangingIPL.Ref = ValueSelected;
	Else	
		DataForChangingIPL = Undefined;
	EndIf;
	Return DataForChangingIPL
EndFunction

// End StandardSubsystems.Properties

&AtClientAtServerNoContext
Procedure SetActionStatusHint(Item, StatusValue, ApprovalIsNotAvailable)
	
	ToolTipText = NStr("vi = 'Cần chọn trạng thái';
						|ru = 'Необходимо выбрать статус';
						|en = 'Select a status'; fa = 'Select a status';
						|it = 'Select a status';
						|pl = 'Select a status';
						|tr = 'Durum seçilmelidir'");
	
	If StatusValue = PredefinedValue("Enum.StatusesOfPriceTypeValidity.NotValid") Then
		ToolTipText = NStr("vi = 'Dạng giá này đã hết hiệu lực và chưa được kích hoạt';
							|ru = 'Действие вида цен прекращено или не начато';
							|en = 'The price type is no longer valid or has not yet come into effect'; fa = 'The price type is no longer valid or has not yet come into effect';
							|it = 'The price type is no longer valid or has not yet come into effect';
							|pl = 'The price type is no longer valid or has not yet come into effect';
							|tr = 'Fiyat türü sonlandırıldı veya başlatılmadı'");
	EndIf;
	
	If StatusValue = PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid") Then
		
		If ApprovalIsNotAvailable Then
			ToolTipText = NStr("vi = 'Việc thiết lập trạng thái ""Có hiệu lực"" không được phép đối với phương pháp đặt giá này.
				|Hãy liên hệ với người dùng có vai trò phê duyệt dạng giá hoặc với người quản trị.';
				|ru = 'Установка статуса ""Действует"" недоступно для данного способа задания цены.
				|Обратитесь к пользователю с ролью утверждения видов цен или администратору.';
				|en = 'Setting the ""Valid"" status is unavailable for this pricing method.
				|Contact a user with the ""Price type approval"" role or an administrator.'; fa = 'Setting the ""Valid"" status is unavailable for this pricing method.
				|Contact a user with the ""Price type approval"" role or an administrator.';
				|it = 'Setting the ""Valid"" status is unavailable for this pricing method.
				|Contact a user with the ""Price type approval"" role or an administrator.';
				|pl = 'Setting the ""Valid"" status is unavailable for this pricing method.
				|Contact a user with the ""Price type approval"" role or an administrator.';
				|tr = 'Durum, bu fiyat ayarlama yöntemi için Etkin olarak ayarlanamamaktadır. 
				|Fiyat türü onayı rolüne sahip bir kullanıcıyla veya bir yöneticiyle irtibata geçin.'");
		Else
			ToolTipText = NStr("vi = 'Có thể sử dụng dạng giá trong các chứng từ và tính toán tự động';
								|ru = 'Вид цен может использоваться в документах и автоматических расчетах';
								|en = 'You can use the price type in documents and automatic calculations'; fa = 'You can use the price type in documents and automatic calculations';
								|it = 'You can use the price type in documents and automatic calculations';
								|pl = 'You can use the price type in documents and automatic calculations';
								|tr = 'Fiyat türü, belgelerde ve otomatik hesaplamalarda kullanılabilmektedir'");
		EndIf;
		
	EndIf;
	
	Item.ToolTip = ToolTipText;
	
EndProcedure

&AtClient
Procedure AfterSecurityConfirmationQuestion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ConfirmationOfUnsafeRecordHasBeenReceived = True;
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,, True);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsUnsafeWayToSetPrice(PricingMethod, UnsafeWaysToSetPrices)
	
	Return UnsafeWaysToSetPrices.FindByValue(PricingMethod) <> Undefined;
	
EndFunction

#Region OnChangeAttributes

&AtServer
Procedure MethodForSettingPricesWhenChangesOccurOnServer()
	
	ArrayMethodsForSettingPricesOther = New Array;
	ArrayMethodsForSettingPricesOther.Add(PredefinedValue("Enum.PriceSettingMethods.Manually"));
	ArrayMethodsForSettingPricesOther.Add(PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup"));
	ArrayMethodsForSettingPricesOther.Add(PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes"));
	
	Value = Undefined;
	If DCSSchemeCompliance.Property(StrReplace(StrReplace(String(Object.PricingMethod)," ",""),".",""), Value) Then
		Object.DataCompositionSchema = Value;
	Else
		If ArrayMethodsForSettingPricesOther.Find(Object.PricingMethod) <> Undefined Then
			Object.DataCompositionSchema = TypicalScheme;
		EndIf;
	EndIf;
	
	DataLayoutDiagramWhenChangedOnServer();
	
	SetParametersForCalculationRules();
	
EndProcedure

&AtServer
Procedure SetParametersForCalculationRules()
	If Not PageOfCalculationRulesIsInitialized
		And (Object.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes
		Or Object.PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup
		Or Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice
		Or Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice) Then
		
		InitializeCalculationRulesPage(True);
		
	EndIf;
	
	SetThePriceWithAnArbitraryRequestToTheInformationSecurityData = (Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData);
	
	Items.ModuleMarkUp.AutoMarkIncomplete = True;
	
	// fill in the list of report parameters selection
	If Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
		Or Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors
		Or Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors Then
		
		Items.ParametersOfTheCalculationType.ChoiceList.Clear();
		Items.ParametersOfTheCalculationType.ChoiceList.Add(1, NStr("vi = 'Đơn giá tối đa';
																	|ru = 'Максимальные цены';
																	|en = 'Maximum prices'; fa = 'حداکثر قیمت‌ها';
																	|it = 'Prezzi massimi';
																	|pl = 'Maksymalne ceny';
																	|tr = 'Maksimum fiyatlar'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(2, NStr("vi = 'Đơn giá tối thiểu';
																	|ru = 'Минимальные цены';
																	|en = 'Minimum prices'; fa = 'حداقل قیمت‌ها';
																	|it = 'Prezzi minimi';
																	|pl = 'Minimalne ceny';
																	|tr = 'Minimum fiyatlar'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(3, NStr("vi = 'Đơn giá trung bình';
																	|ru = 'Средние цены';
																	|en = 'Average prices'; fa = 'میانگین قیمت‌ها';
																	|it = 'Prezzi medi';
																	|pl = 'Średnie ceny';
																	|tr = 'Ortalama fiyatlar'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(4, NStr("vi = 'Đơn giá gần nhất';
																	|ru = 'Последние цены';
																	|en = 'Last prices'; fa = 'آخرین قیمت‌ها';
																	|it = 'Ultimi prezzi';
																	|pl = 'Ostatnie ceny';
																	|tr = 'Son fiyatlar'"));
		
		SetAdditionalParameterValues();
		
	ElsIf Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice Then	
		
		Items.ParametersOfTheCalculationType.ChoiceList.Clear();
		Items.ParametersOfTheCalculationType.ChoiceList.Add(1, NStr("vi = 'Đơn giá tối đa';
																	|ru = 'Максимальные цены';
																	|en = 'Maximum prices'; fa = 'حداکثر قیمت‌ها';
																	|it = 'Prezzi massimi';
																	|pl = 'Maksymalne ceny';
																	|tr = 'Maksimum fiyatlar'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(2, NStr("vi = 'Đơn giá tối thiểu';
																	|ru = 'Минимальные цены';
																	|en = 'Minimum prices'; fa = 'حداقل قیمت‌ها';
																	|it = 'Prezzi minimi';
																	|pl = 'Minimalne ceny';
																	|tr = 'Minimum fiyatlar'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(3, NStr("vi = 'Đơn giá trung bình';
																	|ru = 'Средние цены';
																	|en = 'Average prices'; fa = 'میانگین قیمت‌ها';
																	|it = 'Prezzi medi';
																	|pl = 'Średnie ceny';
																	|tr = 'Ortalama fiyatlar'"));
		
		SetAdditionalParameterValues();
		
	ElsIf Object.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
		 	
		Items.ParametersOfTheCalculationType.ChoiceList.Clear();
		Items.ParametersOfTheCalculationType.ChoiceList.Add(1, NStr("vi = 'Không có chi phí bổ sung';
																	|ru = 'Без дополнительных расходов';
																	|en = 'Without additional expenses'; fa = 'بدون هزینه‌های تکمیلی';
																	|it = 'Senza spese aggiuntive';
																	|pl = 'Bez dodatkowych rozchodów';
																	|tr = 'Ek gidersiz'"));
		Items.ParametersOfTheCalculationType.ChoiceList.Add(2, NStr("vi = 'Có chi phí bổ sung';
																	|ru = 'С дополнительными расходами';
																	|en = 'With additional expenses'; fa = 'با هزینه‌های تکمیلی';
																	|it = 'Con spese aggiuntive';
																	|pl = 'Z dodatkowymi rozchodami';
																	|tr = 'Ek giderli'"));
		
		SetAdditionalParameterValues();
		
	EndIf;
	
	If Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors
		Or Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
		Or Object.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
			
		Items.ModuleMarkUp.AutoMarkIncomplete = False;
		Items.ModuleMarkUp.MarkIncomplete = False;
			 
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteValuesOfAdditionalParametersOfVSKD(ParameterName)
	
	ParametersMap = GetMatchingParameters();
	
	If SettingsComposer <> Undefined Then
		
		FoundCorrespondence = ParametersMap.Get(ParameterName);
		
		If FoundCorrespondence <> Undefined Then
			
			FoundParameterValue = SettingsComposer.Settings.DataParameters.FindParameterValue(FoundCorrespondence);
			If FoundParameterValue <> Undefined Then
				
				FoundParameterValue.Value = ThisObject[ParameterName];
				FoundParameterValue.Use = True;
				
				StorageOfDataCompositionSettings = New ValueStorage(SettingsComposer.GetSettings());
				
			EndIf;
					
		EndIf;
		
	EndIf;
	
EndProcedure


&AtServer
Procedure SetAdditionalParameterValues()
	
	ParametersMap = GetMatchingParameters();
	
	If SettingsComposer <> Undefined Then
		For Each Item In ParametersMap Do
			FoundParameterValue = SettingsComposer.Settings.DataParameters.FindParameterValue(Item.Value);
			If FoundParameterValue <> Undefined Then
				ThisObject[Item.Key]	= FoundParameterValue.Value;
			Else
				ThisObject[Item.Key]	= ?(Item.Key = "DepthOfDataAnalysis", 0, 1);
				WriteValuesOfAdditionalParametersOfVSKD(Item.Key);
			EndIf;
		EndDo;
	EndIf;

EndProcedure

&AtServer
Function GetMatchingParameters()
	
	ParametersMap = New Map;	
	
	If Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors
		Or Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors Then
		
		ParametersMap.Insert("ParametersOfTheCalculationType", New DataCompositionParameter("OptionForGroupingPrices"));
		ParametersMap.Insert("DepthOfDataAnalysis", New DataCompositionParameter("AnalysisDepth"));
		
	ElsIf Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice
		Or Object.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice Then
		
		ParametersMap.Insert("ParametersOfTheCalculationType", New DataCompositionParameter("PriceSelection"));
		ParametersMap.Insert("DepthOfDataAnalysis", New DataCompositionParameter("AnalysisDepth"));
		
	ElsIf Object.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
		
		ParametersMap.Insert("ParametersOfTheCalculationType", New DataCompositionParameter("OptionWithAdditionalCosts"));
		 	
	EndIf;
	
	Return ParametersMap
	
EndFunction

&AtServer
Procedure DataLayoutDiagramWhenChangedOnServer()
	
	ShouldSaveSettings();
	
	Var_Key = Object.DataCompositionSchema + StrReplace(StrReplace(String(Object.PricingMethod)," ",""),".","");	

	If Not IsBlankString(Object.DataCompositionSchema) Then
		DescriptionDataLayoutDiagram = SettingPricesCached.GetDescriptionAndLayoutDiagramOfDataByTemplateName(Object.DataCompositionSchema, UsePriceManagementSystem25);
		SetCountryParameter(DescriptionDataLayoutDiagram.DataCompositionSchema, Object.OptionForSpecifyingVATRates, Object.Country);
		InitializeSettingsComposer(DescriptionDataLayoutDiagram.DataCompositionSchema);
	EndIf;
	
	AddressInTempStorage = Undefined;
	If SettingCompliance.Property(Var_Key, AddressInTempStorage) And ValueIsFilled(AddressInTempStorage) Then
		
		StorageOfDataCompositionSettings = GetFromTempStorage(AddressInTempStorage);// ValueStorage
		SettingStorage = StorageOfDataCompositionSettings; // ValueStorage
		Settings = SettingStorage.Get();
		If Settings <> Undefined Then
			SettingsComposer.LoadSettings(SettingStorage.Get());
		EndIf;	

	Else
		
		StorageOfDataCompositionSettings = New ValueStorage(Undefined);// ValueStorage
		
	EndIf;
	
	SettingStorage = StorageOfDataCompositionSettings; // ValueStorage
	ArbitraryFilterIsUsed = SettingStorage.Get() <> Undefined;
	
	PreviousDataCompositionSchema = Object.DataCompositionSchema;
	
	DCSSchemeCompliance.Insert(StrReplace(StrReplace(String(Object.PricingMethod)," ",""),".",""), Object.DataCompositionSchema);
	
EndProcedure

&AtClient
Procedure DataCompositionSchemaOnChange(Item)
	
	DataLayoutDiagramWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure RoundingAccuracyWhenChangedOnClient()
	
	If Not UseAdvancedRoundingSetting Then
		Object.PriceRoundingRules.Clear();
		If Object.Round Then
			NewRow = Object.PriceRoundingRules.Add();
			NewRow.RoundingPrecision = Object.RoundingPrecision;
		EndIf;
	EndIf;
	
	ConfigureTableRoundingRuleServer(ThisForm);
	
EndProcedure

&AtClient
Procedure UseTriggerThresholdsWhenChangingOnClient()

	If Not UseTriggerThresholds Then
		
		Object.Thresholds.Clear();
		Object.ThresholdOnPriceIncreaseFor = 0;
		Object.ThresholdOnPriceDecreaseBy = 0;
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()

	If IsOpen() Then
		Close();
	EndIf;

EndProcedure

&AtServer
Function PlaceRowsOfTablePartInStorage(TypeOfCall)
	
	If StrStartsWith(TypeOfCall, "ClarificationByPriceGroup") Then
		
		Table = Object.PriceGroups.Unload();

	ElsIf TypeOfCall = "SpecifyingCurrenciesByPriceGroup" Then
		 
		Table = Object.Currencies.Unload();

	ElsIf TypeOfCall = "RefinementOfResponseThresholds" Then
		 
		Table = Object.Thresholds.Unload();
		
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		 
		Table = Object.PriceRoundingRules.Unload();
		
	EndIf;
	
	Return PutToTempStorage(Table, ThisForm.UUID);

EndFunction

&AtServer
Procedure ShouldSaveSettings()

	Var_Key = PreviousDataCompositionSchema + StrReplace(StrReplace(String(PreviousPricingMethod)," ",""),".","");
	
	AddressInTempStorage = Undefined;
	
	If StorageOfDataCompositionSettings = Undefined Then
		StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	EndIf;
	
	If SettingCompliance.Property(Var_Key, AddressInTempStorage) Then
		AddressInTempStorage = PutToTempStorage(
			StorageOfDataCompositionSettings,
			AddressInTempStorage);
	Else
		AddressInTempStorage = PutToTempStorage(
			StorageOfDataCompositionSettings,
			UUID);
	EndIf;
	
	SettingCompliance.Insert(Var_Key, AddressInTempStorage);
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	SetUpFormItemsVisibility(ThisForm);
	ConfigureAvailabilityOfFormElements(ThisForm);
	
	Items.PricingMethod.ChoiceList.Clear();
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.Manually);
	
	If UseSeveralPriceTypes Then
		Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.AnotherPriceTypeMarkup);
	EndIf;
	
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.MarkupOnPurchasingPrice);
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.MarkupOnOBEntryPrice);
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.FillByInfobaseDataByCost);
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.FillInByInfobaseDataByVendors);
	If UseCompetitiveIntelligence Then
		Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors);
	EndIf;

	If UseSeveralPriceTypes Then
		Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes);
	EndIf;
	
	Items.PricingMethod.ChoiceList.Add(Enums.PriceSettingMethods.FillInByInfobaseData);
	

	Items.Id.Visible = UseSeveralPriceTypes;
	
	Items.DataCompositionSchema.ChoiceList.Clear();
	
	// Filling in the list of data layout schemes
	WhetherTemplateIsPredefined = Upper("Predefined");
	LengthOfPredefinedTemplateAttribute = StrLen(WhetherTemplateIsPredefined);
	For Each Template In Metadata.FindByType(TypeOf(Object.Ref)).Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			If (Template.Name = "CostShareIntercompanyPredefined"
				Or Template.Name = "CostProfitShareIntercompanyPredefined" 
				Or Template.Name = "CostWithoutAdditionalExpensesPredefined" 
				Or Template.Name = "CostWithAdditionalExpensesPredefined" 
				Or Template.Name = "CurrentEnterprisePricesPredefined" 
				Or Template.Name = "CurrentEnterprisePricesPredefined2_5") 
				And Object.DataCompositionSchema <> Template.Name Then
				Continue;
			EndIf;
			
			If Not UseCompetitiveIntelligence
				And (Template.Name = "MaxCompetitorPricesPredefined"
				Or Template.Name = "AveragePricesOfCompetitorsPredefined"
				Or Template.Name = "MinCompetitorPricesPredefined"
				Or Template.Name = "CompetitorPricesPredefined") Then
				Continue;
			EndIf;
			
			// we don't show outdated layouts
			If (Template.Name = "MaxCompetitorPricesPredefined"
				Or Template.Name = "AveragePricesOfCompetitorsPredefined"
				Or Template.Name = "MinCompetitorPricesPredefined"
				Or Template.Name = "MaxVendorPricesPredefined"
				Or Template.Name = "AverageVendorPricesPredefined"
				Or Template.Name = "MinVendorPricesPredefined"
				) 
				And Template.Name <> Object.DataCompositionSchema Then
				Continue;
			EndIf;
			
			If Upper(Right(Template.Name, LengthOfPredefinedTemplateAttribute)) = WhetherTemplateIsPredefined Then
								
				Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
				
			EndIf;
			
		EndIf;
	EndDo;
	
	UseArbitraryDataCompositionSchemas = Not Common.DataSeparationEnabled();
	If UseArbitraryDataCompositionSchemas Then
		
		TemplatePresentation = NStr("vi = 'Yêu cầu tùy ý';
									|ru = 'Произвольный запрос';
									|en = 'Arbitrary request'; fa = 'Arbitrary request';
									|it = 'Arbitrary request';
									|pl = 'Arbitrary request';
									|tr = 'Serbest sorgu'");
		Items.DataCompositionSchema.ChoiceList.Add("", TemplatePresentation);
		
	EndIf;
	
	RoundingValue             = 0.01;
	EvenIncrement               = False;
	MaximumRoundingValue = 1000;
	PriceRangeBoundary            = -1;
	
	While RoundingValue <= MaximumRoundingValue 
		And (RoundingValue <= PriceRangeBoundary Or PriceRangeBoundary < 0) Do
		
		Items.RoundingPrecision.ChoiceList.Add(RoundingValue);
		RoundingValue = RoundingValue * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureAvailabilityOfFormElements(Form)
	Form.Items.UseForIssuingProductsWorksAndServicesAtFixedCost.Enabled = (Form.ScheduledPriceCurrency = Form.Object.PriceCurrency);
EndProcedure

&AtClientAtServerNoContext
Function AdvancedRoundingSettingsAreUsed(Form)
	
	UseAdvancedRoundingSetting = False;
	
	If Form.Object.PriceRoundingRules.Count() = 1
		And Form.Object.PriceRoundingRules[0].LowerBoundOfPriceRange = 0
		And Form.Object.PriceRoundingRules[0].SmartRounding = 0 Then
		UseAdvancedRoundingSetting = False;
	ElsIf Form.Object.PriceRoundingRules.Count() >= 1 Then
		UseAdvancedRoundingSetting = True;
	Else
		UseAdvancedRoundingSetting = False;
	EndIf;
	
	Return UseAdvancedRoundingSetting;
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	SetUpFormItemsVisibility(ThisForm);
	ConfigureAvailabilityOfFormElements(ThisForm);
	ConfigureTableRoundingRuleServer(ThisForm);
	
EndProcedure

&AtServer
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(FilterRemainingGoodsByShelfLives = False)
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings, DataLayoutDiagramControl");
	
	If FilterRemainingGoodsByShelfLives Then
		// Schema
		DescriptionDataLayoutDiagram = SettingPricesCached.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TypicalScheme, UsePriceManagementSystem25);
		SetCountryParameter(DescriptionDataLayoutDiagram.DataCompositionSchema, Object.OptionForSpecifyingVATRates, Object.Country);
		Addresses.DataCompositionSchema = PutToTempStorage(DescriptionDataLayoutDiagram.DataCompositionSchema, UUID);
		
		// Settings
		Addresses.DataCompositionSettings = PutToTempStorage(SettingsComposerFilterByProducts.GetSettings(), UUID);
		
	Else
		// Schema
		If ValueIsFilled(Object.DataCompositionSchema) Or StorageOfDataCompositionSchema = Undefined Then
			TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
			TemplateParameters1.Ref 		= Object.Ref;
			TemplateParameters1.TemplateName 	= Object.DataCompositionSchema;
			TemplateParameters1.UsePriceManagementSystem25 	= UsePriceManagementSystem25;
			
			SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1);
			DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
		Else
			SchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
			DataCompositionSchema = SchemaStorage.Get();
		EndIf;
		
		If DataCompositionSchema = Undefined Then
			DataCompositionSchema = Catalogs.TypesOfPrices.CreateNewDataLayoutScheme();
		EndIf;
		
		// we remove from the fields available for selection, which are used in the selection scheme for the nomenclature
		If Not Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData Then
			DatasetFields = DataCompositionSchema.DataSets[0].Fields;
			DescriptionDataLayoutDiagram = SettingPricesCached.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TypicalScheme, UsePriceManagementSystem25);
			LayoutOfSelectionByProductRange = DescriptionDataLayoutDiagram.DataCompositionSchema;//DataCompositionSchema
			For Each ProductSelectionField In LayoutOfSelectionByProductRange.DataSets[0].Fields Do
				If Not ProductSelectionField.UseRestriction.Condition Then
					DataSetField = DatasetFields.Find(ProductSelectionField.Field);
					If DataSetField <> Undefined Then
						DataSetField.UseRestriction.Condition 			= True;
						DataSetField.AttributeUseRestriction.Condition = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		SetCountryParameter(DataCompositionSchema, Object.OptionForSpecifyingVATRates, Object.Country);
		Addresses.DataCompositionSchema 			= PutToTempStorage(DataCompositionSchema, UUID);
		Addresses.DataLayoutDiagramControl 	= PutToTempStorage(DataCompositionSchema, UUID);
		
		// Settings
		SettingsStorageVariable = StorageOfDataCompositionSettings;// ValueStorage
		Settings = SettingsStorageVariable.Get();
		If ValueIsFilled(Settings) Then
			Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
		EndIf;
	EndIf;
	
	Return Addresses;
	
EndFunction

&AtServer
Function GetXML(Value)
	
	Record = New XMLWriter();
	Record.SetString();
	XDTOSerializer.WriteXML(Record, Value);
	Return Record.Close();
	
EndFunction

&AtServer
Procedure ApplyChangesToProductSelectionSettings(Result)
	
	Settings = GetFromTempStorage(Result);
	ThisObject.SettingsComposerFilterByProducts.LoadSettings(Settings);

	StorageOfFilterByItemsDataCompositionSettings = New ValueStorage(Settings);
	
EndProcedure

&AtServer
Procedure ApplyChangesToDataLayoutScheme(AddressOfDataLayoutSchemaInStorage, AddressOfDataCompositionSettings, AddressOfDataLayoutSchemaControlInStorage = Undefined)
	
	If ValueIsFilled(Object.DataCompositionSchema) Then
		
		TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
		TemplateParameters1.Ref 		= Object.Ref;
		TemplateParameters1.TemplateName 	= Object.DataCompositionSchema;
		TemplateParameters1.UsePriceManagementSystem25 	= UsePriceManagementSystem25;
		
		SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1);
		If AddressOfDataLayoutSchemaControlInStorage = Undefined Then
			DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
		Else
			DataCompositionSchema = GetFromTempStorage(AddressOfDataLayoutSchemaControlInStorage);
		EndIf;
		
		// If the data layout scheme from the layout <> is obtained from the data layout scheme editor.
		If GetXML(DataCompositionSchema) <> GetXML(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage)) Then
			Object.DataCompositionSchema   = "";
			StorageOfDataCompositionSchema = New ValueStorage(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage));
		EndIf;
		
		SetCountryParameter(SchemeAndSettings.DataCompositionSchema, Object.OptionForSpecifyingVATRates, Object.Country);
		InitializeSettingsComposer(SchemeAndSettings.DataCompositionSchema);
		
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
			SettingsStorageVariable = StorageOfDataCompositionSettings;//ValueStorage
			SettingsComposer.LoadSettings(SettingsStorageVariable.Get());
		Else
			StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
		
	Else
		
		Schema = GetFromTempStorage(AddressOfDataLayoutSchemaInStorage);
		SetCountryParameter(Schema, Object.OptionForSpecifyingVATRates, Object.Country);
		StorageOfDataCompositionSchema = New ValueStorage(Schema);
		
		SettingsComposer = New DataCompositionSettingsComposer;
		Try
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
		Except
			WriteLogEvent(NStr("vi = 'Đơn giá';
								|ru = 'Цены';
								|en = 'Prices'; fa = 'قیمت‌ها';
								|it = 'Prezzi';
								|pl = 'Prices';
								|tr = 'Fiyatlar'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
		SettingsComposer.LoadSettings(Schema.DefaultSettings);
		SettingsComposer.Refresh();
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
			SettingsStorageVariable = StorageOfDataCompositionSettings;//ValueStorage
			SettingsComposer.LoadSettings(SettingsStorageVariable.Get());
		Else
			StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
		
	EndIf;
	
	SettingsStorageVariable = StorageOfDataCompositionSettings;//ValueStorage
	ArbitraryFilterIsUsed = SettingsStorageVariable.Get() <> Undefined;
	
EndProcedure

&AtServer
Procedure InitializeSettingsComposer(SchemeAndSettingsForInitialization)
	// The resulting settings can be equal to the default settings of the scheme.
	SettingsComposer = New DataCompositionSettingsComposer;
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemeAndSettingsForInitialization));
	Except
		WriteLogEvent(NStr("vi = 'Đơn giá';
							|ru = 'Цены';
							|en = 'Prices'; fa = 'قیمت‌ها';
							|it = 'Prezzi';
							|pl = 'Prices';
							|tr = 'Fiyatlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SettingsComposer.LoadSettings(SchemeAndSettingsForInitialization.DefaultSettings);
	SettingsComposer.Refresh();
EndProcedure

&AtServer
Procedure InitializeCalculationRulesPage(InitializeBasicFormula)
	
	If Not PageOfCalculationRulesIsInitialized Then
		
		TableOfBasePrices = Catalogs.TypesOfPrices.GetTableOfBasePrices(Object.Ref);
		ValueToFormAttribute(TableOfBasePrices, "AvailableBasicPriceTypes");

		ListOfAvailableBasicTypesOfPrices = New ValueList();
		ListOfAvailableBasicTypesOfPrices.LoadValues(TableOfBasePrices.UnloadColumn("Ref"));
		
		NewArray = New Array();
		NewParameter1 = New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True);
		NewArray.Add(NewParameter1);
		NewParameter1 = New ChoiceParameter("TypesOfPrices", ListOfAvailableBasicTypesOfPrices);
		NewArray.Add(NewParameter1);
	
		NewParameters = New FixedArray(NewArray);
		Items.BasicPriceType.ChoiceParameters = NewParameters;
		
		BuildTreeOfOperators();
		
		PageOfCalculationRulesIsInitialized = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BuildTreeOfOperators()
	
	OperatorParameters = New Structure;
	OperatorParameters.Insert("StandardOperators", True);
	OperatorParameters.Insert("BooleanOperators", True);
	OperatorParameters.Insert("Functions", True);
	
	OperatorsTreeStorageAddress = ProcessingOfFormulas.BuildTreeOfOperators(OperatorParameters, UUID);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureTableRoundingRuleServer(Form)
	
	If Form.Object.PriceRoundingRules.Count() > 0 Then
		Form.Object.PriceRoundingRules.Sort("LowerBoundOfPriceRange");
	EndIf;
	
	MaxIndex = Form.Object.PriceRoundingRules.Count() - 1;
	For IndexOf = 0 To MaxIndex Do
		
		If Form.Object.PriceRoundingRules.Count() = 1 And Form.Object.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange = 0 Then
			PriceRange = NStr("vi = 'Tất cả đơn giá';
								|ru = 'Все цены';
								|en = 'All prices'; fa = 'همه قیمت‌ها';
								|it = 'Tutti i prezzi';
								|pl = 'Wszystkie ceny';
								|tr = 'Tüm fiyatlar'");
		Else
			
			If IndexOf = MaxIndex Then
				
				PriceRange = NStr("vi = 'Cao hơn %StartOfRange_%';
									|ru = 'Свыше %StartOfRange_%';
									|en = 'More than %StartOfRange_%'; fa = 'More than %StartOfRange_%';
									|it = 'Superiore a %StartOfRange_%';
									|pl = 'Ponad %StartOfRange_%';
									|tr = '%StartOfRange_% üstü'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%", Form.Object.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange);
				
			Else
				
				PriceRange = NStr("vi = 'Từ %StartOfRange_%đến %EndingOfRange%';
									|ru = 'От %StartOfRange_% до %EndingOfRange%';
									|en = 'From %StartOfRange_% to %EndingOfRange%'; fa = 'From %StartOfRange_% to %EndingOfRange%';
									|it = 'Da %StartOfRange_% a %EndingOfRange%';
									|pl = 'Od %StartOfRange_% do %EndingOfRange%';
									|tr = 'Başlangıcı %StartOfRange_% bitişi %EndingOfRange%'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%",    Form.Object.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange);
				PriceRange = StrReplace(PriceRange, "%EndingOfRange%", Form.Object.PriceRoundingRules[IndexOf + 1].LowerBoundOfPriceRange);
				
			EndIf;
			
			If ValueIsFilled(Form.Object.PriceCurrency) Then
				PriceRange = PriceRange + " " + Form.Object.PriceCurrency;
			EndIf;
			
		EndIf;
		
		Form.Object.PriceRoundingRules[IndexOf].PriceRange = PriceRange;
		
		SetExample(Form, IndexOf);
		
	EndDo;
	
EndProcedure

&AtServer
Function BasicPriceTypesServer()
	
	BasicTypesOfPricesArray = New Array();
	
	For Each PriceKind In AvailableBasicPriceTypes Do
		BasicTypesOfPricesArray.Add(PriceKind.Id);
	EndDo;
	
	Return BasicTypesOfPricesArray;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetUpFormItemsVisibility(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.ParametersOfPriceSettingMethod.Visible = False;
	Items.ParametersOfTheCalculationType.Visible = False;
	Items.DepthOfDataAnalysis.Visible = False;

	Items.AdvancedSettingsPage.Visible = False;
	
	Items.PriceCurrency.Visible = Form.UseMultipleCurrencies;
	Items.GroupCurrencyRefinementByPriceGroups.Visible = Form.UseMultipleCurrencies;
	
	Items.UseWhileTransferringProductsToMaterialProvider.Visible = False;
	Items.UseWhileTransferringProductsToMaterialProvider.Visible = Form.UseProduction;
	Items.UseForIssuingProductsWorksAndServicesAtFixedCost.Visible = Form.UseProduction;
	Items.UseForWholesaleToCustomers.Visible = Form.UseSeveralPriceTypes;
	
	Items.GroupClarificationByPriceGroups.Visible = False;
	Items.GroupBasicCalculationFormula.Visible = False;
	Items.GroupMarkUpForTheBasicPriceType.Visible = False;
	Items.ExchangeRateMarkupGroup.Visible = False;
	Items.ItemSelectionGroup_3.Visible = False;
	
	Items.SKDPage.Visible = False;
	Items.CalculationRulesPage.Visible = False;

	Items.ItemSelectionGroup_3.Visible = True;
	
	
	If Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseData")
		Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataOnReceipt") Then

		Items.ItemSelectionGroup_3.Visible = False;
			
		Items.SKDPage.Visible = True;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
		
		Items.CalculationRulesPage.Visible = True;
		Items.GroupClarificationByPriceGroups.Visible= True;

		Items.GroupBasicCalculationFormula.Visible   = True;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
		
		Items.CalculationRulesPage.Visible = True;
		Items.GroupClarificationByPriceGroups.Visible= True;
		
		Items.GroupMarkUpForTheBasicPriceType.Visible  = True;
		Items.ExchangeRateMarkupGroup.Visible = True;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
		Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice") Then
		
		Items.ParametersOfTheCalculationType.Visible = True;
		Items.DepthOfDataAnalysis.Visible = True;
		Items.AdvancedSettingsPage.Visible = True;
			
		Items.CalculationRulesPage.Visible = True;
		Items.GroupClarificationByPriceGroups.Visible= True;

		Items.ExchangeRateMarkupGroup.Visible = True;

	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
			Or Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors") Then
		
		Items.ParametersOfTheCalculationType.Visible = True;
		Items.DepthOfDataAnalysis.Visible = True;
		Items.AdvancedSettingsPage.Visible= True;
		
		Items.CalculationRulesPage.Visible 		= True;
		Items.GroupClarificationByPriceGroups.Visible= True;
		
		Items.ExchangeRateMarkupGroup.Visible = True;
		
	ElsIf Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost") Then 

		Items.ParametersOfTheCalculationType.Visible = True;

		Items.CalculationRulesPage.Visible 		= True;
		Items.GroupClarificationByPriceGroups.Visible= True;
		Items.AdvancedSettingsPage.Visible= True;
		
		Items.ExchangeRateMarkupGroup.Visible = True;
		

	Else
		
		Items.CalculationRulesPage.Visible = True;

	EndIf;
		
	AdjustVisibilityAvailabilityOfRoundingSettings(Form);
	
	SetActionStatusHint(
		Items.ValidityStatus,
		Object.Status,
		ThisIsUnsafeWayToSetPrice(Object.PricingMethod, Form.UnsafeWaysToSetPrices)
			And Not Form.PriceTypeApproval);
	
	Items.CommandBarForm.Visible = Form.UseSeveralPriceTypes;
	Items.Description.Visible = Form.UseSeveralPriceTypes;
	Items.Parent.Visible = Form.UseSeveralPriceTypes;
	Items.ValidityStatus.Visible = Form.UseSeveralPriceTypes;
	
EndProcedure

&AtClient
Procedure DepthOfDataAnalysisClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	
    RequestForm = GetForm(
    			"Catalog.TypesOfPrices.Form.AnalysisDepthSpecificationForm",
    			FormParameters,
    			ThisForm,
    			True);

    RequestForm.Open();
	
EndProcedure

&AtClient
Procedure CompletingEditingSalesDepth() Export
	UpdateSalesDepthPresentation()
EndProcedure

&AtServer
Procedure UpdateSalesDepthPresentation()
	If DepthOfDataAnalysis = 0 Then
		DepthOfDataAnalysisPresentation = New FormattedString(NStr("vi = 'không hạn chế';
																	|ru = 'без ограничений';
																	|en = 'without restrictions'; fa = 'بدون محدودیت';
																	|it = 'senza restrizioni';
																	|pl = 'bez ograniczeń';
																	|tr = 'kısıtlamasız'"),,,,"Change");
	Else
		DepthOfDataAnalysisPresentation = New FormattedString(NStr("vi = 'sử dụng dữ liệu trong những ngày gần đây';
																	|ru = 'использовать данные за последние дней';
																	|en = 'use data for the last days'; fa = 'use data for the last days';
																	|it = 'Utilizzare dati per gli ultimi giorni';
																	|pl = 'używaj danych za ostatnie dni';
																	|tr = 'son günlerin verilerini kullan'"),,,,"Change");
	EndIf;
EndProcedure

&AtServer
Procedure SetValueOfMarginsDiscounts()
	
	If Object.Markup >= 0 Then
		ExtraChargeOrDiscount = 1;
	ElsIf Object.Markup < 0 Then 
		ExtraChargeOrDiscount = -1;
	EndIf;

	ModuleMarkUp = ExtraChargeOrDiscount * Object.Markup;
	
EndProcedure

&AtClient
Procedure ModuleMarkUpOnChange(Item)
	ModuloMarkUpWhenChangingOnServer();
EndProcedure

&AtServer
Procedure ModuloMarkUpWhenChangingOnServer()
	
	Object.Markup = ExtraChargeOrDiscount * ModuleMarkUp;

EndProcedure

&AtClient
Procedure ExtraChargeOrDiscountOnChange(Item)
	ExtraChargeOrDiscountWhenChangingOnServer();
EndProcedure

&AtServer
Procedure ExtraChargeOrDiscountWhenChangingOnServer()

	Object.Markup = ModuleMarkUp * ExtraChargeOrDiscount;
	
EndProcedure

&AtClient
Procedure SetThePriceWithAnArbitraryRequestToTheInformationSecurityDataOnChange(Item)
	
	SetPriceWithArbitraryRequestToInformationSecurityDataWhenChangingOnServer();
	
	SetUpFormItemsVisibility(ThisForm);
	
EndProcedure

&AtServer
Procedure SetPriceWithArbitraryRequestToInformationSecurityDataWhenChangingOnServer()
	
	If SetThePriceWithAnArbitraryRequestToTheInformationSecurityData Then		
		Object.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData;
	Else
		Object.PricingMethod = Enums.PriceSettingMethods.Manually;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateSuggestedIDValue()
	
	If Not Items.Id.ReadOnly Then
		If Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.ImportedFromOzon") Then
			
			
		Else
			Object.Id = TMCommonUseClientServer.GetID(Object.Description);
		EndIf;
	EndIf;
	AddSuggestedIdValueToSelectionList();
	
EndProcedure

&AtClient
Procedure AddSuggestedIdValueToSelectionList()
	
	If Object.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.ImportedFromOzon") Then
	
		
	Else
		Id = TMCommonUseClientServer.GetID(Object.Description);
	EndIf;
	
	Items.Id.ChoiceList.Clear();
	
	If ValueIsFilled(Object.Id) And Object.Id <> Id Then	
		Items.Id.ChoiceList.Add(Object.Id);
	EndIf;
	
	Items.Id.ChoiceList.Add(Id);
	
EndProcedure

&AtClient
Procedure CreateListToSelectPriceTypeAssignments()
	
	ChoiceList = Items.Purpose.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(PredefinedValue("Enum.PriceTypesAssignment.Shared"), NStr("vi = 'tất cả';
																			|ru = 'всех';
																			|en = 'all'; fa = 'همه';
																			|it = 'tutti';
																			|pl = 'wszystkich';
																			|tr = 'tüm'"));

	FOValues = GetFunctionOptionValues();
	
	UseTypesOfPricesForPartners = FOValues.UsePartnersAndCounterparties
		And Not FOValues.ToUseTermsOfSales;
	
	If FOValues.UseSeveralWarehouses Then
		ChoiceList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForWarehouse"), NStr("vi = 'kho bãi';
																								|ru = 'склада';
																								|en = 'warehouse'; fa = 'انبار';
																								|it = 'del magazzino';
																								|pl = 'magazynu';
																								|tr = 'ambar kapsamında'"));
	EndIf;
	
	If FOValues.UseStoreFormats Then
		ChoiceList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForStoreFormat"), NStr("vi = 'khuôn dạng cửa hàng';
																								|ru = 'формата магазинов';
																								|en = 'retail format'; fa = 'قالب خرده‌فروشی';
																								|it = 'del formato del punto vendita';
																								|pl = 'formatu sklepów';
																								|tr = 'mağaza formatı kapsamında'"));
	EndIf;
	
	If UseTypesOfPricesForPartners Then
		ChoiceList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForPartner"), NStr("vi = 'bạn hàng';
																							|ru = 'партнера';
																							|en = 'partner'; fa = 'شریک تجاری';
																							|it = 'del partner';
																							|pl = 'partnera';
																							|tr = 'iş ortağı'"));
	EndIf;
	
	If FOValues.ToUseTermsOfSales Then
		ChoiceList.Add(PredefinedValue("Enum.PriceTypesAssignment.SpecialForTermsOfSales"), NStr("vi = 'thỏa thuận';
																								|ru = 'соглашения';
																								|en = 'agreements'; fa = 'توافق‌نامه‌ها';
																								|it = 'dell''accordo';
																								|pl = 'porozumienia';
																								|tr = 'Anlaşmalar'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetFunctionOptionValues()
	
	Result = New Structure();
	
	Result.Insert("UseStoreFormats", GetFunctionalOption("UseStoreFormats"));
	Result.Insert("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
	Result.Insert("UsePartnersAndCounterparties", GetFunctionalOption("UsePartnersAndCounterparties"));
	Result.Insert("UseSeveralWarehouses", GetFunctionalOption("UseSeveralWarehouses"));

	Return Result;	
EndFunction

&AtClient
Function BasicPriceTypes()
	
	BasicTypesOfPricesArray = New Array();
	
	For Each PriceKind In AvailableBasicPriceTypes Do
		BasicTypesOfPricesArray.Add(PriceKind.Id);
	EndDo;
	
	Return BasicTypesOfPricesArray;
	
EndFunction

&AtServer
Function PutBasePriceViewsInStorage()
	
	Tree = ProcessingOfFormulas.GetEmptyOperandTree();
	For Each TSRow In AvailableBasicPriceTypes Do
		OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
		OperandString_.Id = TSRow.Id;
		OperandString_.Presentation = String(TSRow.Ref);
		OperandString_.DeletionMark = TSRow.DeletionMark;
		OperandString_.ValueType = New TypeDescription("Number");
	EndDo;
	
	AddressInStorage = PutToTempStorage(Tree, UUID);
	
	Return AddressInStorage;
	
EndFunction

&AtClient
Function GetParametersOfPriceEditingForm(Formula)
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Formula", Formula);
	ReturnStructure.Insert("OperandsTree", PutBasePriceViewsInStorage());
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá hợp lệ';
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

&AtClientAtServerNoContext
Procedure SetExample(Form, IndexOf)
	
	Number = 1111.11;
	If Form.Object.PriceRoundingRules.Count() > 1 Then
		LowerBound = Form.Object.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange;
		If IndexOf = Form.Object.PriceRoundingRules.Count() - 1 Then
			UpperBound = LowerBound + 1000;
		Else
			UpperBound = Form.Object.PriceRoundingRules[IndexOf+1].LowerBoundOfPriceRange;
		EndIf;
		Number = LowerBound + Round((UpperBound - LowerBound)/2, 15, 2);
		If Number + 0.11 < UpperBound Then
			Number = Number + 0.11;
		EndIf;
	EndIf;
	
	If Form.Object.PriceRoundingRules[IndexOf].RoundingPrecision <> 0 Or Form.Object.PriceRoundingRules[IndexOf].SmartRounding <> 0 Then
		Price = PriceManagementSystemClientServer.RoundUpPrice(Number, Form.Object.PriceRoundingRules[IndexOf].RoundingPrecision, Form.Object.RoundOffOption);
		Value = PriceManagementSystemClientServer.ApplyPsychologicalRounding(
			Price,
			Form.Object.PriceRoundingRules[IndexOf].SmartRounding);
		
		FormatString = "NFD=2; NGS=' '; NZ=; NG=0";
		Form.Object.PriceRoundingRules[IndexOf].ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Làm tròn %1 đến %2';
				|ru = 'Округлять %1 до %2';
				|en = 'Round %1 to %2'; fa = 'Round %1 to %2';
				|it = 'Arrotondare %1 fino a %2';
				|pl = 'Zaokrąglaj %1 do %2';
				|tr = '%1 değerini %2 boyunca yuvarla'"),
			Format(Number, FormatString),
			Format(Value, FormatString));
	Else
		Form.Object.PriceRoundingRules[IndexOf].ToolTip = NStr("vi = 'Không làm tròn';
																|ru = 'Не округлять';
																|en = 'Do not round off'; fa = 'Do not round off';
																|it = 'Non arrotondare';
																|pl = 'Nie zaokrąglaj';
																|tr = 'Yuvarlama'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureTableRoundingRule()
	
	If Object.PriceRoundingRules.Count() > 1 Then
		ConfigureTableRoundingRuleServer(ThisForm);
	Else
		
		If Object.PriceRoundingRules.Count() = 1 Then
			
			If Object.PriceRoundingRules[0].LowerBoundOfPriceRange = 0 Then
				PriceRange = NStr("vi = 'Tất cả đơn giá';
									|ru = 'Все цены';
									|en = 'All prices'; fa = 'همه قیمت‌ها';
									|it = 'Tutti i prezzi';
									|pl = 'Wszystkie ceny';
									|tr = 'Tüm fiyatlar'");
			Else
				
				PriceRange = NStr("vi = 'Cao hơn %StartOfRange_%';
									|ru = 'Свыше %StartOfRange_%';
									|en = 'More than %StartOfRange_%'; fa = 'More than %StartOfRange_%';
									|it = 'Superiore a %StartOfRange_%';
									|pl = 'Ponad %StartOfRange_%';
									|tr = '%StartOfRange_% üstü'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%", Object.PriceRoundingRules[0].LowerBoundOfPriceRange);
				
				If ValueIsFilled(Object.PriceCurrency) Then
					PriceRange = PriceRange + " " + Object.PriceCurrency;
				EndIf;
				
			EndIf;
			
			Object.PriceRoundingRules[0].PriceRange = PriceRange;
			
			SetExample(ThisForm, 0);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfRoundingSettings(Form)
	
	OnlyViewRoundingData =  Not Form.Object.Round Or Form.Items.Round.ReadOnly;
	
	Form.Items.RoundingPrecision.Visible 						= Not Form.UseAdvancedRoundingSetting; 
	Form.Items.RoundingConstructor.Visible 						= Not Form.UseAdvancedRoundingSetting;
	Form.Items.RefinementOfRoundingSettingsPresentation.Visible 	= Form.UseAdvancedRoundingSetting;

	Form.Items.UseAdvancedRoundingSetting.ReadOnly= OnlyViewRoundingData;
	Form.Items.RoundingPrecision.ReadOnly 						= OnlyViewRoundingData;
	Form.Items.RoundOffOption.ReadOnly 						= OnlyViewRoundingData;
	Form.Items.RoundingConstructor.Enabled 						= Not OnlyViewRoundingData;
	
	Form.Items.RefinementOfRoundingSettingsPresentation.Enabled		= Not OnlyViewRoundingData;
		
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfThresholdSettings(Form)
	
	OnlyViewingThresholdData =  Not Form.UseTriggerThresholds Or Form.Items.UseTriggerThresholds.ReadOnly;
	
	Form.Items.GroupMainTriggerThreshold.ReadOnly = OnlyViewingThresholdData;
	Form.Items.RefinementOfResponseThresholdsPresentation.Enabled	= Not OnlyViewingThresholdData;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAndAvailabilityOfMarketplacePriceSettingElements(Form)

	OnlyViewingMarketplacePriceData = Not Form.UseIntegrationWithOzon;

	Form.Items.ParametersOfPriceSettingMethod.ReadOnly = OnlyViewingMarketplacePriceData;
	Form.Items.ParametersOfPriceSettingMethodCustomType.ReadOnly = OnlyViewingMarketplacePriceData;

EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	AdjustVisibilityAvailabilityOfRoundingSettings(ThisForm);
	AdjustVisibilityAvailabilityOfThresholdSettings(ThisForm);
	SetParametersForCalculationRules();
	AdjustVisibilityAndAvailabilityOfMarketplacePriceSettingElements(ThisForm);

EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfItemsWhenChangingTypeOfPriceView(Form)
	If Form.Object.Purpose =PredefinedValue("Enum.PriceTypesAssignment.Shared") Then
		Form.Items.AGroupOfDataOnAnIndividualTypeOfPrice.Visible = False;
	Else
		Form.Items.AGroupOfDataOnAnIndividualTypeOfPrice.Visible = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityOfVATRatesElements(Form, OpeningForm)
	
	If Not Form.UsePriceManagementSystem25 Then
		Return;
	EndIf;
	
	If Form.Object.OptionForSpecifyingVATRates = PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems") Then
		Form.Items.VATRate.Visible = True;
	Else
		Form.Items.VATRate.Visible = False;
	EndIf;
	
	If Form.UseMultiCountryAccounting Then
		If Form.Object.OptionForSpecifyingVATRates = PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates") Then
			Form.Items.Country.Visible = False;
		Else
			Form.Items.Country.Visible = True;
		EndIf;
	EndIf;
	
	SetAvailabilityOfVATRates(Form, OpeningForm);
	
EndProcedure


&AtServer 
Procedure FillInItemSelectionListOnServer(TagName)

	ChoiceList = Items[TagName].ChoiceList;
	ChoiceList.Clear();


EndProcedure

&AtServerNoContext 
Procedure SetCountryParameter(DataCompositionSchema, OptionForSpecifyingVATRates, Country)

	If	Not ValueIsFilled(OptionForSpecifyingVATRates)
			Or Not ValueIsFilled(Country)
			Or OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates Then
		Return;
	EndIf;
	
	CountryParameter = DataCompositionClientServer.GetParameter(DataCompositionSchema.DefaultSettings, "CountryOfVATRates");
	If Not CountryParameter = Undefined And Not CountryParameter.Value = Country Then
		DataCompositionClientServer.SetParameter(DataCompositionSchema.DefaultSettings, "CountryOfVATRates", Country);
	EndIf;

EndProcedure

#EndRegion

#EndRegion
