#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Searches for a characteristic that is identical to the passed characteristic.if it doesn't find it, it creates a characteristic for the passed item.
//
// Parameters:
//  Products					 - CatalogRef.Products				 - the owner of the new characteristic.
//  CharacteristicsInDocument		 - CatalogRef.ItemsCharacteristics	 - the characteristic specified in the document.
// 
// Returns:
//  CatalogRef.ItemsCharacteristics - a link to an identical characteristic.
//
Function IdenticalCharacteristic(Products, CharacteristicsInDocument) Export
	
	Query = New Query(
		"SELECT TOP 1
		|	ItemsCharacteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Owner = &Products
		|	AND TRIMALL(ItemsCharacteristics.Description) IN
		|			(SELECT
		|				TRIMALL(T.Description) AS Description
		|			FROM
		|				Catalog.ItemsCharacteristics AS T
		|			WHERE
		|				T.Ref = &Characteristic)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	*
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Ref = &Characteristic");
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", CharacteristicsInDocument);
	
	QueryResults = Query.ExecuteBatch();
	
	Selection = QueryResults[0].Select();
	If Selection.Next() Then
		Return Selection.Ref;
	ElsIf QueryResults[1].IsEmpty() Then
		Return Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	FillingValues = QueryResults[1].Unload()[0];
	
	SetPrivilegedMode(True);
	
	NewCharacteristic = Catalogs.ItemsCharacteristics.CreateItem();
	FillPropertyValues(NewCharacteristic, FillingValues,,"Owner");
	NewCharacteristic.Owner = Products;
	For Each TabularSection In CharacteristicsInDocument.Metadata().TabularSections Do
		NewCharacteristic[TabularSection.Name].Load(FillingValues[TabularSection.Name]);
	EndDo;
	NewCharacteristic.Write();
	
	SetPrivilegedMode(False);
	
	Return NewCharacteristic.Ref;
	
EndFunction

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array - a list of the names of the object's details.
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Description");
	NotAttributesToEdit.Add("ItemsCharacteristicForPricing");
	
	Return NotAttributesToEdit;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServer.ProductCharacteristicsProcessingOfSelectionData(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// To call in the method, the value is set to Setpovtisp.Allvisited characteristics of the nomenclature.
// Returns properties of the characteristic details, taking into account the settings made
// in the metadata and pre-defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//
// Returns:
//	FixedStructure - Contains:
//		* Key - String - The name of the props
//		* Value - See Catalogs.Products.PropertyValuesOfProps
//
Function AllAttributes(ItemsType, AccountingFeature) Export
	
	SettingsOfBankingDetailsByType = Catalogs.Products.DependenceOfBankingDetailsOnTypeOfProductItem(ItemsType,
																								AccountingFeature,
																								True,
																								False,
																								True);
	
	BankingDetailsDisabledByFederalDistrict = Catalogs.Products.BankingDetailsDisabledByFederalDistrict(True);
	
	AllAttributes = New Structure;
	
	For Each Attribute In Metadata.Catalogs.ItemsCharacteristics.Attributes Do
		If StrFind(Attribute.Name, "Delete") > 0 Then
			Continue;
		EndIf;
		
		PropertyValues = Catalogs.Products.PropertyValuesOfProps();
		
		PropertyValues.Name = Attribute.Name;
		SettingString = SettingsOfBankingDetailsByType.Find(Attribute, "Attribute");
		
		If SettingString = Undefined Then
			If Attribute.Name = "ItemsCharacteristicForPricing" Then				
				PropertyValues.Use = False;
			Else	
				PropertyValues.Use = BankingDetailsDisabledByFederalDistrict.Find(Attribute.Name) = Undefined;
			EndIf;
		Else
			PropertyValues.Use = SettingString.Use
											And BankingDetailsDisabledByFederalDistrict.Find(Attribute.Name) = Undefined;
		EndIf;
		
		AttributeRepresentation = Attribute.Synonym;
		If Not ValueIsFilled(AttributeRepresentation) Then
			AttributeRepresentation = Attribute.Name;
		EndIf;
		
		PropertyValues.Presentation = AttributeRepresentation;	
		PropertyValues.Type = Attribute.Type;
		PropertyValues.Required_ToFillIn = PropertyValues.Use
													And (Attribute.FillChecking = FillChecking.ShowError);
		
		PropertyValues.RequiredToDisplayWhenCreating = PropertyValues.Use
																And PropertyValues.Required_ToFillIn;
		
		AllAttributes.Insert(Attribute.Name, New FixedStructure(PropertyValues));
	EndDo;
	
	Return New FixedStructure(AllAttributes);
	
EndFunction

Function WorkingNameIsUnique(Object) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ItemsCharacteristics.Ref AS Characteristic
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|WHERE
	|	ItemsCharacteristics.Ref <> &Ref
	|	AND ItemsCharacteristics.Description = &Description
	|	AND ItemsCharacteristics.Owner = &Owner";
	
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Description", Object.Description);
	Query.SetParameter("Owner", Object.Owner);

	Result = Query.Execute();
	
	Return Result.IsEmpty()
	
EndFunction

// Returns a description of the settings for the property's details.
//
// Parameters:
//	Attribute - MetadataObjectAttribute - details of the reference list of nomenclature Characteristics.
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//
// Returns:
//	See Catalogs.Products.PropertyValuesOfProps.
//
Function PropsDescription(Attribute, ItemsType, AccountingFeature) Export
	
	If TypeOf(Attribute) = Type("String")
		Or TypeOf(Attribute) = Type("MetadataObject") Then
		
		AllDetailsOfCharacteristics = SettingsValueCached.AllDetailsOfProductCharacteristics(ItemsType,
																								AccountingFeature);
		
		If TypeOf(Attribute) = Type("String") Then
			AttributeName = Attribute;
		Else
			AttributeName = Attribute.Name;
		EndIf;
		
		Return AllDetailsOfCharacteristics[AttributeName];
		
	ElsIf TypeOf(Attribute) = Type("FixedStructure") Then
		Return Attribute;
	Else
		ExceptionText = NStr("vi = 'Loại tham số bất ngờ mục tin.';
							|ru = 'Неожиданный тип параметра Реквизит.';
							|en = 'Unexpected Attribute parameter type.'; fa = 'Unexpected Attribute parameter type.';
							|it = 'Tipo inaspettato del parametro Requisito.';
							|pl = 'Nieoczekiwany typ parametru Atrybut.';
							|tr = 'Beklenmeyen parametre tipi Öznitelik.'");
		Raise ExceptionText;
	EndIf;
	
EndFunction

Function BankingDetailsWithRedefinedMandatoryFields(ProductKindAttributes, Object) Export
	
	BankingDetailsWithRedefinedMandatoryFields = New Map;
	
	If ProductKindAttributes = Undefined Then
		RequestedDetailsOfTypeOfProduct =
		"WorkingNameTemplateCharacteristics,
		|ItemsType,
		|AccountingFeature";
		
		If Object = Undefined
			Or Object.Owner = Undefined Then
			ProductKindAttributes = TMCommonUse.DefaultValuesForItemDetails(Catalogs.ItemKinds.EmptyRef(),
			RequestedDetailsOfTypeOfProduct);
		Else
			If TypeOf(Object.Owner) = Type("CatalogRef.ItemKinds") Then	
				ProductKind = Object.Owner;	
			Else
				ProductKind = TMCommonUse.DefaultValuesForItemDetails(Object.Owner, "ProductKind").ProductKind;
			EndIf;
			ProductKindAttributes = TMCommonUse.DefaultValuesForItemDetails(ProductKind, RequestedDetailsOfTypeOfProduct);
		EndIf;	
	EndIf;
	
	BankingDetailsWithRedefinedMandatoryFields.Insert("Description", 
		Not ValueIsFilled(ProductKindAttributes.WorkingNameTemplateCharacteristics));
	
	BankingDetailsWithRedefinedMandatoryFields.Insert("Principal",ProductKindAttributes.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis
																		Or ProductKindAttributes.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByPartner);
																		
	BankingDetailsWithRedefinedMandatoryFields.Insert("Counterparty",
																		ProductKindAttributes.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByPartner);
	
	
	Return BankingDetailsWithRedefinedMandatoryFields;
	
EndFunction

Function AttributesNotToCheck(Object) Export
	
	NotCheckedAttributeArray = New Array;
	
	BankingDetailsWithRedefinedMandatoryFields = 
		BankingDetailsWithRedefinedMandatoryFields(Undefined, Object);

	For Each KeyValue In BankingDetailsWithRedefinedMandatoryFields Do
		
		If Not KeyValue.Value Then
			NotCheckedAttributeArray.Add(KeyValue.Key);
		EndIf;
		
	EndDo;
		
	Return NotCheckedAttributeArray;
	
EndFunction

// Returns the visibility and header settings for form elements. Used for building the form and table
// document of the item card.
// Parameters:
//  Object - CatalogObject.Products, FormDataStructure - element for which you need to work out the logic of communication details
//	ProductKindAttributes - See NewStructureOfNewTypeOfProduct
//
// Returns:
//  Structure - structure with keys:
//		* VisibilityOfElements - See UsingElements
//		* ItemsTitles - See ItemsTitles
//
Function VisibilityAndHeaderSettings(Object, ProductKindAttributes) Export
	
	VisibilityAndHeaderSettings = New Structure;
	
	VisibilityOfElements = UsingElements(Object,ProductKindAttributes);
	SetPrivilegedMode(True);
	ItemsTitles = ItemsTitles(Object, VisibilityOfElements,ProductKindAttributes);
	SetPrivilegedMode(False);
		
	VisibilityAndHeaderSettings.Insert("VisibilityOfElements", VisibilityOfElements);
	VisibilityAndHeaderSettings.Insert("ItemsTitles", ItemsTitles);
		
	Return VisibilityAndHeaderSettings;
	
EndFunction

// Returns a structure with element visibility.
// Parameters:
//	PassedObject - CatalogObject.ItemsCharacteristics
//	ProductKindAttributes - See NewStructureOfNewTypeOfProduct
//
// Returns:
//	Structure - the visibility structure of the elements. The key is the name of the element, the values are visibility.
//
Function UsingElements(PassedObject, ProductKindAttributes)
	
	UsingElements = New Structure;
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	#Region SettingUpByProductType
		
	DetailsSettingsByTypeOfProduct = Catalogs.Products.AttributeSettingTable(ProductKindAttributes.Ref,
																	ProductKindAttributes.ItemsType,
																	ProductKindAttributes.AccountingFeature,
																	ProductKindAttributes.UseVariants,
																	False,
																	"ItemsCharacteristics");
	
	For Each RowOfTables In DetailsSettingsByTypeOfProduct Do
		AttributeName     = RowOfTables.AttributeName;
		If RowOfTables.IsAddlAttribute Then
			FormItemName = "AdditionalAttributeValue_"
				+ StrReplace(?(RowOfTables.IsCommonAttribute,
						Upper(String(RowOfTables.Set.UUID())),
						Upper(String(RowOfTables.PropertiesSet.UUID()))),
					"-",
					"x")
				+ "_"
				+ StrReplace(Upper(String(RowOfTables.Property.UUID())), "-", "x");
			
			UsingElements.Insert(FormItemName, RowOfTables.Use 
																And Catalogs.Products.VisibilityOfProps(RowOfTables,
																AttributeName,
																False,
																RowOfTables));
		Else
			If AttributeName = "ItemsCharacteristicForPricing" Then
				UsingElements.Insert(AttributeName, RowOfTables.Use);
			Else
				UsingElements.Insert(AttributeName, RowOfTables.Use
																And (Catalogs.Products.VisibilityOfProps(AttributeName,
																					AttributeName,
																					False,
																					RowOfTables)));
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	UsingElements.Insert("HyperlinkGoSetComposition", 
									AccessRight("View", Metadata.Catalogs.ProductKitConfigurations)
									And ProductKindAttributes.ItemsType = Enums.ItemsTypes.Set
									And ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems);
	
	Return UsingElements;
	
EndFunction

// Returns a structure with the titles of the items.
// Parameters:
//	Object - CatalogObject.Products - item in the nomenclature reference list
//	Structuraladjustment - Structure - structure-of-sight items.
//
// Returns:
//	Structure - the structure of the element headers. The key is the name of the element, the values are the title.
//
Function ItemsTitles(Object, VisibilityOfElements, ProductKindAttributes)
	
	ItemsTitles = New Structure;
	
	If ProductKindAttributes.ItemsType = Enums.ItemsTypes.Work_5 Then
		ItemsTitles.Insert("AgencyServicesGroup", NStr("vi = 'Công việc được thực hiện theo hợp đồng môi giới';
														|ru = 'Работа выполняется по агентскому договору';
														|en = 'Work is performed under the agency agreement'; fa = 'Work is performed under the agency agreement';
														|it = 'Il lavoro viene eseguito in base ad un accordo di agenzia';
														|pl = 'Praca jest wykonywana w ramach umowy agencyjnej';
														|tr = 'İş, acentelik sözleşmesi kapsamında yürütülür'"));
	Else
		ItemsTitles.Insert("AgencyServicesGroup", NStr("vi = 'Dịch vụ được cung cấp theo hợp đồng môi giới';
														|ru = 'Услуга реализуется по агентскому договору';
														|en = 'The service is rendered under agency agreement'; fa = 'خدمت بر اساس قرارداد عاملیت ارائه می‌شود';
														|it = 'Il servizio viene erogato in base ad un accordo di agenzia';
														|pl = 'Usługa jest świadczona w ramach umowy agencyjnej';
														|tr = 'Hizmet, acentelik sözleşmesi kapsamında gerçekleştirilmektedir'"));
	EndIf;
	
	Picture = New Picture;
	WarningPicture = PictureLib.WarningStartingFromRowBeginning;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ConfigurationOptionsForProductRange.LineNumber AS LineNumber
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	&HyperlinkGoSetComposition
	|	AND ConfigurationOptionsForProductRange.Ref = &ItemKitConfiguration
	|	AND NOT ConfigurationOptionsForProductRange.Ref.DeletionMark";
	
	If  Catalogs.Products.SectionIsVisible("HyperlinkGoSetComposition", VisibilityOfElements) Then 
		ItemKitConfiguration = SetsServerCall.DefaultProductConfigurationOption(
											Object.Owner,
											Object.Ref);
		Query.SetParameter("ItemKitConfiguration", ItemKitConfiguration);
	Else
		Query.SetParameter("ItemKitConfiguration", Catalogs.ProductKitConfigurations.EmptyRef());
	EndIf;	
	
	Query.SetParameter("ItemKitConfiguration", ItemKitConfiguration);
		
	QueryOptions = Query.FindParameters();
	
	For Each QueryParameter In QueryOptions Do
		If StrFind(QueryParameter.Name, "HyperlinkGoSetComposition") <> 0 Then
			Query.SetParameter(QueryParameter.Name, Catalogs.Products.SectionIsVisible(QueryParameter.Name, VisibilityOfElements));
		EndIf;
	EndDo;
	
	SetPrivilegedMode(True);
	
	Samples = Query.ExecuteBatch();
	
	SetPrivilegedMode(False);
	ItemVisibility = False;
	
	If Catalogs.Products.SectionIsVisible("HyperlinkGoSetComposition", VisibilityOfElements) Then
		QueryResult = Samples[0]; // QueryResult 
		Count = QueryResult.Select().Count();
		If Count <> 0 Then
			HyperlinkHeader = New FormattedString(NStr("vi = 'Đặt thành phần';
														|ru = 'Состав набора';
														|en = 'Set content'; fa = 'محتوای مجموعه';
														|it = 'Composizione del set';
														|pl = 'Skład zestawu';
														|tr = 'Set kapsamı'") + " (" + Count + ")",,,,"SetComposition");
		Else
			HyperlinkHeader = New FormattedString(New FormattedString(NStr("vi = 'Tùy chỉnh tập hợp';
																			|ru = 'Настроить набор';
																			|en = 'Configure set'; fa = 'Configure set';
																			|it = 'Impostare l''insieme';
																			|pl = 'Skonfiguruj zestaw';
																			|tr = 'Seti ayarla'"),,,,"CustomizeSet"),
																							WarningPicture);
		EndIf;
		ItemsTitles.Insert("HyperlinkGoSetComposition", HyperlinkHeader);
	EndIf;
			
	Return ItemsTitles;

EndFunction

// Parameters:
// 	ProductKind - CatalogRef.ItemKinds
// 	
// Returns:
// 	FixedStructure:
// 		* Ref - CatalogRef.ItemKinds
// 		* NameTemplateForPrintingCharacteristics - String
// 		* WorkingNameTemplateCharacteristics - String
// 		* ProhibitEditingWorkingTitleOfItemVariants - Boolean
// 		* DisableNameChangeToPrintItemVariant - Boolean
// 		* ItemsType - EnumRef.ItemsTypes
// 		* AccountingFeature - EnumRef.ItemAccountingFeatures
// 		* CharacteristicsPropertySet - CatalogRef.AdditionalAttributesAndInfoSets
// 		* UseVariants - EnumRef.ItemVariantsUsageOptions
//
Function NewStructureOfNewTypeOfProduct(ProductKind) Export
	
	AttributesNames =
	"Ref,
	|NameTemplateForPrintingCharacteristics,
	|WorkingNameTemplateCharacteristics,
	|ProhibitEditingWorkingTitleOfItemVariants,
	|DisableNameChangeToPrintItemVariant,
	|ItemsType,
	|AccountingFeature,
	|CharacteristicsPropertySet,
	|UseVariants,
	|SettingsOfPriceKeyByItemVariant";
	
	Return New FixedStructure(
		TMCommonUse.DefaultValuesForItemDetails(ProductKind, AttributesNames));	
	
EndFunction

#EndRegion

#EndIf
#EndIf