#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("KeepAccountingByBatch", False);
	AdditionalProperties.Insert("BatchSettingsAreTakenFromOtherItemsKind", False);
	AdditionalProperties.Insert("UseCharacteristics", False);
	AdditionalProperties.Insert("UseVariants", Enums.ItemVariantsUsageOptions.DontUse);
	AdditionalProperties.Insert("ReplenishCharacteristics", False);
	AdditionalProperties.Insert("ReFillSeries", False);
	
	If Not IsNew() Then
		OldDetails = Common.ObjectAttributesValues(Ref, 
			"KeepAccountingByBatch, BatchSettingsAreTakenFromOtherItemsKind, UseCharacteristics, UseVariants, SettingsOfPriceKeyByItemVariant, SettingsOfPriceKeyByBatch, ItemVariantsAttributesForPriceKey.AttributeName, BatchAttributesForPriceKey.AttributeName");
		FillPropertyValues(AdditionalProperties, OldDetails);
		
		AdditionalProperties.ReplenishCharacteristics = 
				SettingsOfPriceKeyByItemVariant <> Enums.FilterOptionForPriceKey.DontUse
				And Not ValueIsFilled(ItemVariantsOwner)
				And Not SettingsOfPriceKeyByItemVariant = OldDetails.SettingsOfPriceKeyByItemVariant;
				
		If Not AdditionalProperties.ReplenishCharacteristics And Not ValueIsFilled(ItemVariantsOwner) And SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes Then
			ArrayOfOldProps = OldDetails.DetailsOfCharacteristicsForPriceKeyPropsName.Unload().UnloadColumn("AttributeName");
			ArrayCurDetails = ItemVariantsAttributesForPriceKey.UnloadColumn("AttributeName");
			AdditionalProperties.ReplenishCharacteristics = Not Common.IdenticalCollections(ArrayOfOldProps, ArrayCurDetails);
		EndIf;

		AdditionalProperties.ReFillSeries =
				SettingsOfPriceKeyByBatch <> Enums.FilterOptionForPriceKey.DontUse 
				And Not ValueIsFilled(BatchOwner)
				And Not SettingsOfPriceKeyByBatch = OldDetails.SettingsOfPriceKeyByBatch;
			
		If Not AdditionalProperties.ReFillSeries And Not ValueIsFilled(ItemVariantsOwner) And SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes Then			
			ArrayOfOldProps = OldDetails.SeriesDetailsForPriceKeyPropsName.Unload().UnloadColumn("AttributeName");
			ArrayCurDetails = BatchAttributesForPriceKey.UnloadColumn("AttributeName");
			AdditionalProperties.ReFillSeries = Not Common.IdenticalCollections(ArrayOfOldProps, ArrayCurDetails);
		EndIf;
	EndIf;

	// If necessary, we will reset the pricing settings by owner
	UpdatePricingSettingsByOwner("SettingsOfPriceKeyByItemVariant");
	
	UpdatePricingSettingsByOwner("SettingsOfPriceKeyByBatch");
	
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ThisObject);
	
	// Let's update the elements of the reference set of additional requirements and PVC additional requirements.
	TMPropertyManagement.UpdateAdditionalPropertyFields(ThisObject,
		"Catalog_Products");
	TMPropertyManagement.UpdateAdditionalPropertyFields(ThisObject,
		"Catalog_ItemsCharacteristics",
		"CharacteristicsPropertySet",
		" " + NStr("vi = '(Đối với đặc tính)';
					|ru = '(Для характеристик)';
					|en = '(For variants)'; fa = '(For variants)';
					|it = '(Per le caratteristiche)';
					|pl = '(Dla charakterystyk)';
					|tr = '(Varyantlar için)'"),
		UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
			Or UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems);
	TMPropertyManagement.UpdateAdditionalPropertyFields(ThisObject,
		"Catalog_ItemsBatches",
		"BatchPropertySet",
		" " + NStr("vi = '(Đối với sê-ri)';
					|ru = '(Для серий)';
					|en = '(For batch)'; fa = '(For batch)';
					|it = '(Per le serie)';
					|pl = '(Dla serii)';
					|tr = '(Partiler için)'"));
		
	FillTSAccountingPoliciesWithWarehousesAndDivisions();
	
	SettingTransitionHistoryDetailsForNewFormulas();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ObjectMetadata = Metadata(); // MetadataObjectCatalog
	
	If Not IsFolder Then
		
		PropertiesSet              = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
		CharacteristicsPropertySet = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
		BatchPropertySet         = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
		
		MetadataObjectAttribute = ObjectMetadata.Attributes.NameTemplateForPrintingOfProductItem; // MetadataObjectAttribute
		NameTemplateForPrintingOfProductItem = MetadataObjectAttribute.FillValue;
		WorkingNameTemplateOfProductItem = "";
		ProhibitEditingWorkingTitleOfItems = False;
		RestrictNameChangeToPrintItems = False;
		
		MetadataObjectAttribute = ObjectMetadata.Attributes.NameTemplateForPrintingCharacteristics; // MetadataObjectAttribute
		NameTemplateForPrintingCharacteristics = MetadataObjectAttribute.FillValue;
		WorkingNameTemplateCharacteristics = "";
		ProhibitEditingWorkingTitleOfItemVariants = False;
		DisableNameChangeToPrintItemVariant = False;
		
		WorkingNameTemplateSetOfSeries = "";
				
		If GetFunctionalOption("UseProductCategories") Then
			If Not CopiedObject.ProductCategoriesCommonWithAnotherKindOfItems Then
				ProductCategoriesCommonWithAnotherKindOfItems = True;
				ProductCategoryOwner = CopiedObject.Ref;
			EndIf;
		EndIf;
		
		If CopiedObject.KeepAccountingByBatch Then
			If Not CopiedObject.BatchSettingsAreTakenFromOtherItemsKind Then
				BatchSettingsAreTakenFromOtherItemsKind = True;
				BatchOwner = CopiedObject.Ref;
			EndIf;
		EndIf;
		
		If CopiedObject.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
			UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind;
			ItemVariantsOwner = CopiedObject.Ref;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
		
	NotCheckedAttributeArray = New Array;
	If Not Catalogs.ItemAccessGroups.AccessGroupsAreUsed()
		Or Not GetFunctionalOption("UseMultipleKindsOfProducts") Then
		NotCheckedAttributeArray.Add("AccessGroup");
	EndIf;
	
	NotCheckedAttributeArray.Add("BatchAccountingPolicies");
	NotCheckedAttributeArray.Add("BatchAccountingPolicies.Warehouse");
	NotCheckedAttributeArray.Add("BatchAccountingPolicies.BatchAccountingPolicy");
	
	If KeepAccountingByBatch
		And Not BatchSettingsAreTakenFromOtherItemsKind Then
		
		If Not (UseShelfLifeOnBatchRegistration
			Or UseBatchProductionDate) Then
			
			NotCheckedAttributeArray.Add("PrecisionOfBatchShelfLifeIndication");
			
		EndIf;
		
		KeyAttributes = New Array;
		KeyAttributes.Add("Warehouse");
		
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "BatchAccountingPolicies", KeyAttributes, Cancel,,False);
		
		If Not Cancel
			And BatchAccountingPolicy = Catalogs.BatchAccountingPolicies.SeriesAreNotUsed 
			And BatchAccountingPolicies.FindRows(New Structure("BatchAccountingPolicy",
															Catalogs.BatchAccountingPolicies.SeriesAreNotUsed)).Count()
															= BatchAccountingPolicies.Count() Then
			MessageText = NStr("vi = 'Đã bật sử dụng sê-ri, nhưng chưa tùy chỉnh chính sách sê-ri cho kho bãi cụ thể nào.';
								|ru = 'Включено использование серий, но политика учета серий не назначена ни одному складу.';
								|en = 'The use of batch is enabled but no batch accounting policy is assigned to any warehouse.'; fa = 'The use of batch is enabled but no batch accounting policy is assigned to any warehouse.';
								|it = 'L''uso delle serie è abilitato, ma il criterio di contabilità delle serie non è assegnato ad alcun magazzino.';
								|pl = 'Włączono używanie serii, ale polityka ewidencji serii nie jest wyznaczona ani jednemu magazynowi.';
								|tr = 'Parti kullanımı etkinleştirildi, fakat toplu muhasebe politikası herhangi bir ambara atanmadı.'");
			
			CommonClientServer.MessageToUser(MessageText,Ref,,,Cancel);
		EndIf;
		
		DescriptionsOfUseOfSeriesProps = Catalogs.ItemKinds.DescriptionsOfUseOfSeriesProps();
		
		ThereIsSettingEnabled = False;
		
		For Each AttributeDetails In DescriptionsOfUseOfSeriesProps Do
			If ThisObject[AttributeDetails.SettingName] Then
				ThereIsSettingEnabled = True;
				Break;
			EndIf;
		EndDo;
		
		If Not ThereIsSettingEnabled Then
			MessageText = NStr("vi = 'Đã bật sử dụng sê-ri, nhưng nó không được tùy chỉnh sử dụng những mục tin nào. Cần vô hiệu hóa sử dụng ít nhất một mục tin.';
								|ru = 'Включено использование серий, но не настроено, какие реквизиты серии будут использоваться. Необходимо выключить использование хотя бы одного реквизита.';
								|en = 'The use of batch is enabled but the batch attributes are not configured. Disable the use of one or several attribute.'; fa = 'The use of batch is enabled but the batch attributes are not configured. Disable the use of one or several attribute.';
								|it = 'L''utilizzo delle serie è attivo ma non è configurato quali requisiti delle serie verranno utilizzati. È necessario disattivare l''utilizzo di almeno un requisito.';
								|pl = 'Zostało włączone korzystanie z serii, lecz nie jest skonfigurowane, jakie rekwizyty serii będą wykorzystywane. Należy wyłączyć korzystanie z przynajmniej jednego rekwizytu.';
								|tr = 'Parti kullanımı etkinleştirildi, fakat hangi parti özniteliklerinin kullanılacağını ayarlanmadı. En az bir özniteliğin kullanımını devre dışı bırakmanız gerekmektedir.'");
			CommonClientServer.MessageToUser(MessageText,Ref,,,Cancel);
		EndIf;
		
	Else
		
		NotCheckedAttributeArray.Add("PrecisionOfBatchShelfLifeIndication");
		NotCheckedAttributeArray.Add("BatchUsageSettings");
		NotCheckedAttributeArray.Add("BatchAccountingPolicy");
		
	EndIf;
	
	If Not BatchSettingsAreTakenFromOtherItemsKind Then
		NotCheckedAttributeArray.Add("BatchOwner");
	Else
		NotCheckedAttributeArray.Add("BatchOwner");
		If Not ValueIsFilled(BatchOwner) Then
			MessageText = NStr("vi = 'Đã tạo tùy chỉnh sao cho sê-ri được sử dụng như trong dạng mặt hàng khác, nhưng đồng thời không chọn dạng mặt hàng này.';
								|ru = 'Сделана настройка, что серии используются также, как в другом виде номенклатуры, но при этом не выбран этот вид.';
								|en = 'The batches are set to ""common with another item kind"" but no item kind is selected.'; fa = 'The batches are set to ""common with another item kind"" but no item kind is selected.';
								|it = 'La configurazione è impostata in modo che le serie vengono utilizzate come nell''altro tipo di articolo, ma nello stesso tempo il tipo non è selezionato.';
								|pl = 'Dokonano ustawień, zgodnie z którymi serie są używane tak samo, jak w innym rodzaju towarów, jednak nie wybrano tego rodzaju.';
								|tr = 'Partilerin başka bir öğe türünde olduğu gibi kullanıldığı bir ayar yapıldı fakat bu tür seçilmedi.'");
			CommonClientServer.MessageToUser(MessageText,,"OptionOfSeriesSettings",, Cancel);
		EndIf;
	EndIf;
	
	If Not UseCharacteristics Then
		NotCheckedAttributeArray.Add("UseVariants");
		NotCheckedAttributeArray.Add("ItemVariantsOwner");
	ElsIf UseVariants <> Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		NotCheckedAttributeArray.Add("ItemVariantsOwner");
	Else
		NotCheckedAttributeArray.Add("ItemVariantsOwner");
		If Not ValueIsFilled(ItemVariantsOwner) Then
			MessageText = NStr("vi = 'Đã tạo tùy chỉnh, đặc tính chung với dạng mặt hàng khác, nhưng đồng thời không chọn dạng mặt hàng này.';
								|ru = 'Сделана настройка, характеристики общие с другим видом номенклатуры, но при этом не выбран этот вид.';
								|en = 'Item variants are set to ""Common with another item kind"" but no item kind is selected.'; fa = 'Item variants are set to ""Common with another item kind"" but no item kind is selected.';
								|it = 'La configurazione è impostata, le caratteristiche sono le stesse dell''altro tipo di articolo, ma nello stesso tempo il tipo non è selezionato.';
								|pl = 'Dokonano ustawień, zgodnie z którymi charakterystyki są wspólne z innym rodzajem towarów, jednak nie wybrano tego rodzaju.';
								|tr = 'Varyantların başka bir ürün türüyle ortak olduğu ayar yapıldı fakat bu tür seçilmedi.'");
			CommonClientServer.MessageToUser(MessageText,,"UseVariants","Object", Cancel);
		EndIf;
	EndIf;
	
	If Not ProductCategoriesCommonWithAnotherKindOfItems Then
		NotCheckedAttributeArray.Add("ProductCategoryOwner");
	Else
		NotCheckedAttributeArray.Add("ProductCategoryOwner");
		If Not ValueIsFilled(ProductCategoryOwner) Then
			MessageText = NStr("vi = 'Đã tạo tùy chỉnh, thể loại hàng hóa chung với dạng mặt hàng khác, nhưng đồng thời không chọn dạng mặt hàng này.';
								|ru = 'Сделана настройка, товарные категории общие с другим видом номенклатуры, но при этом не выбран этот вид.';
								|en = 'Product categories are set to ""common with another item kind"" but no item kind is selected.'; fa = 'Product categories are set to ""common with another item kind"" but no item kind is selected.';
								|it = 'La configurazione è impostata, le categorie merceologiche sono le stesse dell''altro tipo di articolo, ma nello stesso tempo il tipo non è selezionato.';
								|pl = 'Dokonano ustawień, zgodnie z którymi kategorie towarowe są wspólne z innym rodzajem towarów, jednak nie wybrano tego rodzaju.';
								|tr = 'Ürün kategorilerinin başka bir öğe türü ile ortak olduğu ayar yapıldı fakat bu tür seçilmedi.'");
			CommonClientServer.MessageToUser(MessageText,,"ConfigureProductCategories",, Cancel);
		EndIf;
	EndIf;	
	
	If Not Catalogs.ItemAccessGroups.AccessGroupsAreUsed() Then
		NotCheckedAttributeArray.Add("AccessGroup");
	EndIf;
	
	If Not UsePackages Then
		NotCheckedAttributeArray.Add("PackagingGroup");
	EndIf;
	
	If Not SuppliedInReusablePackage Then
		NotCheckedAttributeArray.Add("ReusablePackageItems");
		NotCheckedAttributeArray.Add("ReusablePackageVariant");
	ElsIf Not Catalogs.Products.ItemVariantsAreUsed(ReusablePackageItems) Then
		NotCheckedAttributeArray.Add("ReusablePackageVariant");
	EndIf;
	
	TemplateStructure_ = New Structure;
	TemplateStructure_.Insert("NameTemplateForPrintingOfProductItem", NameTemplateForPrintingOfProductItem);
	TemplateStructure_.Insert("NameTemplateForPrintingCharacteristics", NameTemplateForPrintingCharacteristics);
	TemplateStructure_.Insert("WorkingNameTemplateOfProductItem", WorkingNameTemplateOfProductItem);
	TemplateStructure_.Insert("WorkingNameTemplateCharacteristics", WorkingNameTemplateCharacteristics);
	
	ErrorTextTemplate = NStr("vi = 'Trong công thức khuôn mẫu ""%TemplateName%"" đã tìm thấy lỗi';
							|ru = 'В формуле шаблона ""%TemplateName%"" обнаружены ошибки';
							|en = 'Errors were detected in the formula of template ""%TemplateName%""'; fa = 'Errors were detected in the formula of template ""%TemplateName%""';
							|it = 'Nella formula del modello ""%TemplateName%"" sono presenti errori';
							|pl = 'W formule szablonu ""%TemplateName%"" wykryto błędy';
							|tr = '""%TemplateName%"" şablon formülünde hatalar bulundu'");
	ObjectMetadata = Metadata();
	
	For Each Item In TemplateStructure_ Do
		
		Template = Item.Value;
		
		If ValueIsFilled(Template) Then
			
			ErrorText = StrReplace(
			ErrorTextTemplate,
			"%TemplateName%",
			ObjectMetadata.Attributes[Item.Key].Synonym);
			
			ExpectedResultType = New TypeDescription("String");
			FormulaOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(Template);
			ParametersOfFormulaValidationMessages = ProcessingOfFormulas.FormulaValidationParameters();
			ParametersOfFormulaValidationMessages.Field = Item.Key;
			ParametersOfFormulaValidationMessages.DataPath = "Object";
			ParametersOfFormulaValidationMessages.ErrorMessage = ErrorText;
			
			PropertiesSets = New Structure("PropertiesSet, BatchPropertySet, CharacteristicsPropertySet");
			FillPropertyValues(PropertiesSets, ThisObject);
			
			OperandsTree = Catalogs.ItemKinds.PrepareTreeOfOperands(PropertiesSets, Item.Key);
			
			TypesOfOperands = New Map;
			Catalogs.ItemKinds.GetTypesOfOperands(OperandsTree, TypesOfOperands);
			
			ParametersOfFormulaValidationMessages.Insert("TypesOfOperands", New FixedMap(TypesOfOperands));
			
			If Not ProcessingOfFormulas.CheckFormula(Template, FormulaOperands, ExpectedResultType, ParametersOfFormulaValidationMessages) Then
				Cancel = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes 
		And UseVariants <> Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind 
		And ItemVariantsAttributesForPriceKey.Count() = 0 Then
			
			MessageText = NStr("vi = 'Đã bật sử dụng đặc tính trong thiết lập giá theo mục tin, nhưng chưa chọn mục tin nào.';
								|ru = 'Включено использование характеристик в ценообразовании по реквизитам, но не выбран ни один реквизит.';
								|en = 'The use of variants in the pricing by attributes is enabled, but no attributes are selected.'; fa = 'The use of variants in the pricing by attributes is enabled, but no attributes are selected.';
								|it = 'Incluso l''utilizzo delle caratteristiche nell''elaborazione di prezzo per attributi, ma non è stato selezionato alcun attributo.';
								|pl = 'Włączono używanie charakterystyk w tworzeniu cen wg atrybutów, ale nie wybrano żadnego atrybutu.';
								|tr = 'Öznitelik fiyatlandırmasında varyantların  kullanımı etkinleştirildi, fakat herhangi bir öznitelik seçilmedi.'");
						
			CommonClientServer.MessageToUser(MessageText,Ref,,,Cancel);
		
	EndIf;
	
	If SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes And Not BatchSettingsAreTakenFromOtherItemsKind Then
		If BatchAttributesForPriceKey.Count() = 0 Then			
			
			MessageText = NStr("vi = 'Đã bật sử dụng sê-ri trong thiết lập giá theo mục tin, nhưng chưa chọn mục tin nào.';
								|ru = 'Включено использование серий в ценообразовании по реквизитам, но не выбран ни один реквизит.';
								|en = 'The use of batch in the pricing by attributes is enabled, but no attributes are selected.'; fa = 'The use of batch in the pricing by attributes is enabled, but no attributes are selected.';
								|it = 'Incluso l''utilizzo delle serie nell''elaborazione di prezzo per attributi, ma non è stato selezionato alcun attributo.';
								|pl = 'Włączono używanie serii w tworzeniu cen wg atrybutów, ale nie wybrano żadnego atrybutu.';
								|tr = 'Öznitelik fiyatlandırmasında partilerin kullanımı etkinleştirildi, fakat herhangi bir öznitelik seçilmedi.'");
						
			CommonClientServer.MessageToUser(MessageText,Ref,,,Cancel);
			
		EndIf;
		
	EndIf;
	
	CheckMatchingDetailsForSelection(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	If AdditionalProperties.IsNew
		And Not GetFunctionalOption("UseMultipleKindsOfProducts") Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	COUNT(DISTINCT ItemKinds.Ref) AS NumberOfSpecies
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	NOT ItemKinds.IsFolder";
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			If Selection.NumberOfSpecies > 2 Then
				SetPrivilegedMode(True);
				
				Constants.UseMultipleKindsOfProducts.Set(True);
				
				SetPrivilegedMode(False);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	ProductionManagement.ConfigureUseOfSeriesInProduction22();
	UpdateBatchUsageFlagsInWarehousesAndProduction();
	UpdateRelatedProductTypes();
	
	UpdateResult = SettingPricesServer.UpdateSpecificationsAndSeriesPricing(Ref, AdditionalProperties);
	
	If Not UpdateResult.Result Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If IsFolder Then
		Return;	
	EndIf;
	
	Catalogs.ItemKinds.FillDefaultAttributes(ThisObject);
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ThisObject);	
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	PropertyManager.BeforeDeleteObjectKind(ThisObject, "PropertiesSet");
	PropertyManager.BeforeDeleteObjectKind(ThisObject, "BatchPropertySet");
	PropertyManager.BeforeDeleteObjectKind(ThisObject, "CharacteristicsPropertySet");
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure SettingTransitionHistoryDetailsForNewFormulas()
	
	If IsBlankString(ItemsPrintDescriptionTemplateSwitchingToNewFormulasHistory)
		And Not IsBlankString(NameTemplateForPrintingOfProductItem) Then
		ItemsPrintDescriptionTemplateSwitchingToNewFormulasHistory = NameTemplateForPrintingOfProductItem;
	EndIf;
	If IsBlankString(VariantPrintDescriptionTemplateSwitchingToNewFormulasHistory)
		And Not IsBlankString(NameTemplateForPrintingCharacteristics) Then
		VariantPrintDescriptionTemplateSwitchingToNewFormulasHistory = NameTemplateForPrintingCharacteristics;
	EndIf;
	If IsBlankString(ItemsWorkingDescriptionTemplateSwitchingToNewFormulasHistory)
		And Not IsBlankString(WorkingNameTemplateOfProductItem) Then
		ItemsWorkingDescriptionTemplateSwitchingToNewFormulasHistory = WorkingNameTemplateOfProductItem;
	EndIf;
	If IsBlankString(BatchWorkingDescriptionTemplateSwitchingToNewFormulasHistory)
		And Not IsBlankString(WorkingNameTemplateSetOfSeries) Then
		BatchWorkingDescriptionTemplateSwitchingToNewFormulasHistory = WorkingNameTemplateSetOfSeries;
	EndIf;
	If IsBlankString(VariantWorkingDescriptionTemplateSwitchingToNewFormulasHistory)
		And Not IsBlankString(WorkingNameTemplateCharacteristics) Then
		VariantWorkingDescriptionTemplateSwitchingToNewFormulasHistory = WorkingNameTemplateCharacteristics;
	EndIf;
	
EndProcedure

Procedure UpdateBatchUsageFlagsInWarehousesAndProduction()
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("SkipUpdatingSeriesUsageFlag") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BatchAccountingPolicies.Warehouse,
	|	TRUE AS KeepAccountingByBatch,
	|	MAX(BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches) AS UseCostAccountingByBatches
	|INTO ItemKinds
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|
	|GROUP BY
	|	BatchAccountingPolicies.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Warehouses.Ref AS Warehouse,
	|	ISNULL(ItemKinds.KeepAccountingByBatch, FALSE) AS UseItemsBatch,
	|	ISNULL(ItemKinds.UseCostAccountingByBatches, FALSE) AS UseCostAccountingByBatches
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN ItemKinds AS ItemKinds
	|		ON Warehouses.Ref = ItemKinds.Warehouse
	|WHERE
	|	NOT Warehouses.IsFolder
	|	AND (ISNULL(ItemKinds.KeepAccountingByBatch, FALSE) <> Warehouses.UseItemsBatch
	|			OR ISNULL(ItemKinds.UseCostAccountingByBatches, FALSE) <> Warehouses.UseCostAccountingByBatches)";
	Query.Text = Query.Text + "
	|
	|UNION ALL
	|
	|SELECT
	|	BusinessStructure.Ref,
	|	ISNULL(ItemKinds.KeepAccountingByBatch, FALSE) AS UseItemsBatch,
	|	ISNULL(ItemKinds.UseCostAccountingByBatches, FALSE) AS UseCostAccountingByBatches
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|		LEFT JOIN ItemKinds AS ItemKinds
	|		ON BusinessStructure.Ref = ItemKinds.Warehouse
	|WHERE
	|	ISNULL(ItemKinds.KeepAccountingByBatch, FALSE) <> BusinessStructure.UseItemsBatch
	|		OR ISNULL(ItemKinds.UseCostAccountingByBatches, FALSE) <> BusinessStructure.UseCostAccountingByBatches";	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If TypeOf(Selection.Warehouse) = Type("CatalogRef.Warehouses") Then
			
			WarehouseObject = Selection.Warehouse.GetObject();
			
			WarehouseObject.UseItemsBatch  = Selection.UseItemsBatch;
			WarehouseObject.UseCostAccountingByBatches = Selection.UseCostAccountingByBatches;
			
			WarehouseObject.AdditionalProperties.Insert("SkipUpdatingSeriesUsageFlag");
			
			WarehouseObject.Write();
			
		Else
			
			DivisionObject = Selection.Warehouse.GetObject();
			
			DivisionObject.UseItemsBatch  = Selection.UseItemsBatch;
			DivisionObject.UseCostAccountingByBatches = Selection.UseCostAccountingByBatches;
			
			DivisionObject.AdditionalProperties.Insert("SkipUpdatingSeriesUsageFlag");
			DivisionObject.Write();
		
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds warehouses and production units to PM Politikiuchetasery
// that have not yet been added to PM.
//
Procedure FillTSAccountingPoliciesWithWarehousesAndDivisions()
	
	If AdditionalProperties.Property("SkipFillingInTSSeriesAccountingPolicy") Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	BatchAccountingPolicies.Warehouse AS Warehouse,
	|	BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy
	|INTO TTSeriesAccountingPolicies
	|FROM
	|	&BatchAccountingPolicies AS BatchAccountingPolicies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Warehouses.Ref                  AS Warehouse,
	|	&DefaultSeriesAccountingPolicy AS BatchAccountingPolicy
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN TTSeriesAccountingPolicies AS BatchAccountingPolicies
	|		ON Warehouses.Ref = BatchAccountingPolicies.Warehouse
	|WHERE
	|	BatchAccountingPolicies.Warehouse IS NULL
	|	AND NOT Warehouses.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	Departments.Ref           AS Warehouse,
	|	&DefaultSeriesAccountingPolicy AS BatchAccountingPolicy
	|FROM
	|	Catalog.BusinessStructure AS Departments
	|		LEFT JOIN TTSeriesAccountingPolicies AS BatchAccountingPolicies
	|		ON Departments.Ref = BatchAccountingPolicies.Warehouse
	|WHERE
	|	BatchAccountingPolicies.Warehouse IS NULL
	|	AND Departments.ProductionBusinessUnit";
	
	Query.SetParameter("BatchAccountingPolicies", BatchAccountingPolicies.Unload());
	Query.SetParameter("DefaultSeriesAccountingPolicy", BatchAccountingPolicy);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		NewRow = BatchAccountingPolicies.Add();
		FillPropertyValues(NewRow, Selection);
	EndDo;
	
EndProcedure

Procedure UpdateRelatedProductTypes()
	
	If AdditionalProperties.IsNew Then
		Return;
	EndIf;
	
	ProcessedProductTypes = New Array();
	
	If AdditionalProperties.KeepAccountingByBatch
		And Not AdditionalProperties.BatchSettingsAreTakenFromOtherItemsKind Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ItemKinds.Ref AS ProductKind
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	ItemKinds.BatchOwner = &BatchOwner";
		
		Query.SetParameter("BatchOwner", Ref);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			ProcessedProductTypes.Add(Selection.ProductKind);

			ObjectToChange = Selection.ProductKind.GetObject();
			
			ObjectToChange.KeepAccountingByBatch = KeepAccountingByBatch;
			If Not KeepAccountingByBatch Then
				ObjectToChange.BatchSettingsAreTakenFromOtherItemsKind = False;
				// The remaining fields will be cleared when writing
				ObjectToChange.Write();
				Continue;
			EndIf;
			
			ObjectToChange.BatchUsageSettings        = BatchUsageSettings;
			ObjectToChange.PrecisionOfBatchShelfLifeIndication = PrecisionOfBatchShelfLifeIndication;
			ObjectToChange.BatchAccountingPolicies.Load(BatchAccountingPolicies.Unload());
			ObjectToChange.SettingsOfPriceKeyByBatch           = SettingsOfPriceKeyByBatch;
			
			// The remaining fields will be filled in when recording
			ObjectToChange.AdditionalProperties.Insert("SkipFillingInTSSeriesAccountingPolicy");
			ObjectToChange.AdditionalProperties.Insert("SkipUpdatingSeriesUsageFlag");
			
			ObjectToChange.Write();
			
		EndDo;
	EndIf;
	
	If AdditionalProperties.UseCharacteristics
		And Not AdditionalProperties.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ItemKinds.Ref AS ProductKind
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	ItemKinds.ItemVariantsOwner = &ItemVariantsOwner
		|	AND NOT ItemKinds.Ref IN (&ProcessedProductTypes)";
		
		Query.SetParameter("ItemVariantsOwner", Ref);
		Query.SetParameter("ProcessedProductTypes", ProcessedProductTypes);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			ObjectToChange = Selection.ProductKind.GetObject();
			ObjectToChange.SettingsOfPriceKeyByItemVariant = SettingsOfPriceKeyByItemVariant;

			// The remaining fields will be filled in when recording
			ObjectToChange.AdditionalProperties.Insert("SkipFillingInTSSeriesAccountingPolicy");
			ObjectToChange.AdditionalProperties.Insert("SkipUpdatingSeriesUsageFlag");
			
			ObjectToChange.Write();
			
		EndDo;
	EndIf;
	
EndProcedure

// Checks whether there are matching details for quick selection of items and characteristics.
// If there is, it displays a message to the user, because it is not allowed to add the same 
// additional details to the quick selection panel for both the item and the characteristics. 
// If this setting is required, you should create two separate additional details 
// and specify them for the item and characteristics, respectively.
//
// For example:
//	Brand (for the item) and brand (for characteristics).
//
// Parameters:
//	Cancel - Boolean, Undefined - the variable that the failure flag is written to.
//
Procedure CheckMatchingDetailsForSelection(Cancel)
	
	If Not UseCharacteristics Then
		Return;
	EndIf;
		
	MatchingDetails = MatchingDetailsForSelectingCharacteristicProductRange();
	
	If MatchingDetails.Count() > 0 Then
		
		Cancel = True;
		
		For Each AttributeParameters In MatchingDetails Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mục tin bổ sung để lọc mặt hàng tại dòng %1 trùng với mục tin bổ sung để lọc đặc tính.';
					|ru = 'Дополнительный реквизит для отбора номенклатуры в строке %1 совпадает с дополнительным реквизитом для отбора характеристик.';
					|en = 'Additional attribute for the item filter in line %1 matches an additional attribute for the variant filter.'; fa = 'Additional attribute for the item filter in line %1 matches an additional attribute for the variant filter.';
					|it = 'Il requisito aggiuntivo per la selezione dell''articolo nella riga %1 corrisponde al requisito aggiuntivo per la selezione delle caratteristiche.';
					|pl = 'Atrybut dodatkowy do wyboru towarów w wierszu %1 jest taki sam, jak atrybut dodatkowy do wyboru charakterystyk.';
					|tr = '%1 satırındaki öğe filtresine yönelik ek öznitelik, varyant filtresine yönelik ek öznitelik ile aynıdır.'"), 
				AttributeParameters.LineNumber);
			
			Field = "AttributesOfQuickFilterOfProducts[" + Format(AttributeParameters.RowIndex, "ND=10; NG=0") + "].AttributeRepresentation";
			
			CommonClientServer.MessageToUser(MessageText, , Field, "Object");
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns:
//	 Array of Structure:
//		* Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//		* LineNumber - Number
//		* RowIndex - Number
//
Function MatchingDetailsForSelectingCharacteristicProductRange()
	
	MatchingDetails = New Array;
	
	Filter = New Structure("Property");
	
	For Each TablRow In AttributesOfQuickFilterOfProducts Do
		
		If Not TablRow.IsAddlAttribute
			Or Not TablRow.Used Then
			Continue;
		EndIf;
		
		FillPropertyValues(Filter, TablRow);
		
		RowsArray = AttributesOfItemVariantQuickFilter.FindRows(Filter);
		
		If RowsArray.Count() > 0 Then
			AttributeParameters = New Structure("Property, LineNumber, RowIndex", 
				TablRow.Property, TablRow.LineNumber, AttributesOfQuickFilterOfProducts.IndexOf(TablRow));
			
			MatchingDetails.Add(AttributeParameters);
		EndIf;
		
	EndDo;
	
	Return MatchingDetails;
	
EndFunction

// Updates pricing settings by owner
//
// Parameters:
//	AttributeName - String - by characteristics or series.
//
Procedure UpdatePricingSettingsByOwner(AttributeName)
	
	If AttributeName = "SettingsOfPriceKeyByItemVariant" Then
		SettingsOwner = ItemVariantsOwner;
		TabularSectionName = "ItemVariantsAttributesForPriceKey";
	Else
		SettingsOwner = BatchOwner;
		TabularSectionName = "BatchAttributesForPriceKey";
	EndIf;
	
	If Not ValueIsFilled(SettingsOwner) Then
		Return;
	EndIf;

	ObjectAttribute = ThisObject[AttributeName];
	
	ObjectAttribute = Common.ObjectAttributeValue(SettingsOwner, AttributeName);
	
	If ThisObject[AttributeName] <> ObjectAttribute Then
		ThisObject[AttributeName] = ObjectAttribute;
	EndIf;
	
	If ObjectAttribute = Enums.FilterOptionForPriceKey.UseByAttributes Then
		// get a list of additional details by which to search for har-ku
		DetailsForPriceKey = Catalogs.ItemKinds.GetDetailsForPricingKey(SettingsOwner, "Characteristics");
		ThisObject[TabularSectionName].Load(DetailsForPriceKey);
	Else
		ThisObject[TabularSectionName].Clear();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
#EndIf