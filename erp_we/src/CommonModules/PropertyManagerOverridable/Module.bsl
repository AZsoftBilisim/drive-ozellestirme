///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Gets details of predefined property sets.
//
// Parameters:
//  Sets - ValueTree:
//     * Name           - String - a property set name. Generated from the full metadata
//          object name by replacing a period (".") by an underscore ("_").
//          For example, Document_SalesOrder.
//     * Id - UUID - a UUID of the predefined property set.
//          Should not be repeated in other property sets.
//          ID format Random UUID (Version 4).
//          To get an ID, in 1C:Enterprise mode calculate the value of
//          the "New UniqueID" platform constructor or use an online generator,
//          for example, https://www.uuidgenerator.net/version4.
//     * Used  - Undefined
//                     - Boolean - indicates whether a property set is used.
//          For example, you can use it to hide a set by functional options.
//          Default value - Undefined, matches the True value.
//     * IsFolder     - Boolean - True if the property set is a folder.
//
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	

EndProcedure

// Gets descriptions of second-level property sets in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - a set presentation in the passed language:
//     * Key     - String - a property set name. For example, Catalog_Partners_Common.
//     * Value - String - a set description for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["Catalog_Partners_Common"] = NStr("en='Common'; fa = 'مشترک';", LanguageCode);
//
Procedure OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode) Export
	Descriptions["Document_ProductionOperation2_2_Overall"]    = NStr("vi = 'Chung';
																		|ru = 'Общие';
																		|en = 'Common'; fa = 'مشترک';
																		|it = 'Generali';
																		|pl = 'Common';
																		|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_SubAssets_Overall"] = NStr("vi = 'Chung';
													|ru = 'Общие';
													|en = 'Common'; fa = 'مشترک';
													|it = 'Generali';
													|pl = 'Common';
													|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_Products_Overall"] = NStr("vi = 'Chung';
													|ru = 'Общие';
													|en = 'Common'; fa = 'مشترک';
													|it = 'Generali';
													|pl = 'Common';
													|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_Assets_Overall"] = NStr("vi = 'Chung';
													|ru = 'Общие';
													|en = 'Common'; fa = 'مشترک';
													|it = 'Generali';
													|pl = 'Common';
													|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_Partners_Customers"] = NStr("vi = 'Khách hàng';
														|ru = 'Клиенты';
														|en = 'Customers'; fa = 'مشتریان';
														|it = 'Clienti';
														|pl = 'Customers';
														|tr = 'Müşteriler'", LanguageCode);
	Descriptions["Catalog_Partners_Overall"] = NStr("vi = 'Chung';
													|ru = 'Общие';
													|en = 'Common'; fa = 'مشترک';
													|it = 'Generali';
													|pl = 'Common';
													|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_Partners_Vendors"] = NStr("vi = 'Nhà cung cấp';
													|ru = 'Поставщики';
													|en = 'Vendors'; fa = 'تأمین‌کنندگان';
													|it = 'Fornitori';
													|pl = 'Vendors';
													|tr = 'Tedarikçiler'", LanguageCode);
	Descriptions["Catalog_Partners_Competitors"] = NStr("vi = 'Đối thủ cạnh tranh';
														|ru = 'Конкуренты';
														|en = 'Competitors'; fa = 'رقبا';
														|it = 'Concorrenti';
														|pl = 'Competitors';
														|tr = 'Rakipler'", LanguageCode);
	Descriptions["Catalog_Partners_OtherItems"] = NStr("vi = 'Khác';
														|ru = 'Прочие';
														|en = 'Other'; fa = 'سایر';
														|it = 'Altri';
														|pl = 'Other';
														|tr = 'Diğer'", LanguageCode);
	Descriptions["Catalog_ItemsBatches_Overall"] = NStr("vi = 'Chung';
														|ru = 'Общие';
														|en = 'Common'; fa = 'مشترک';
														|it = 'Generali';
														|pl = 'Common';
														|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_ItemsCharacteristics_Overall"] = NStr("vi = 'Chung';
																|ru = 'Общие';
																|en = 'Common'; fa = 'مشترک';
																|it = 'Generali';
																|pl = 'Common';
																|tr = 'Ortak'", LanguageCode);
	Descriptions["Catalog_Incidents_Overall"] = NStr("vi = 'Chung';
													|ru = 'Общие';
													|en = 'Common'; fa = 'مشترک';
													|it = 'Generali';
													|pl = 'Common';
													|tr = 'Ortak'", LanguageCode);
EndProcedure

// Fills object property sets. Usually required if there is more than one set.
//
// Parameters:
//  Object       - AnyRef      - a reference to an object with properties.
//               - ClientApplicationForm - a form of the object, to which properties are attached.
//               - FormDataStructure - details of the object, to which properties are attached.
//
//  RefType    - Type - a type of the property owner reference.
//
//  PropertiesSets - ValueTable:
//     * Set - CatalogRef.AdditionalAttributesAndInfoSets
//     * SharedSet - Boolean - True if the property set contains properties
//                             common for all objects.
//    Then, form item properties of the FormGroup type and the usual group kind
//    or page that is created if there are more than one set excluding
//    a blank set that describes properties of deleted attributes group.
//
//    If the value is Undefined, use the default value.
//
//    For any group of a client application form.
//     * Height                   - Number
//     * Title                - String
//     * ToolTip                - String
//     * VerticalStretch   - Boolean
//     * HorizontalStretch - Boolean
//     * ReadOnly           - Boolean
//     * TitleTextColor      - Color
//     * Width                   - Number
//     * TitleFont           - Font
//                    
//    For regular group and page.
//     * Group              - ChildFormItemsGroup
//
//    For regular group.
//     * Representation              - UsualGroupRepresentation
//
//    For page.
//     * Picture                 - Picture
//     * ShowTitle      - Boolean
//
//  StandardProcessing - Boolean - an initial value is True. Indicates whether to get
//                         the default set when PropertiesSets.Count() is equal to zero.
//
//  AssignmentKey   - Undefined - (initial value) - specifies to calculate
//                      the assignment key automatically and add PurposeUseKey and WindowOptionsKey to
//                      form property values
//                      to save form changes (settings, position, and size)
//                      separately for different sets.
//                       For example, for each product kind - its own sets.
//
//                   - String - (not more than 32 characters) - use the specified assignment key
//                      to add it to form property values.
//                      Blank string - do not change form key properties as
//                      they are set in the form and already consider differences of sets.
//
//                    Addition has format "PropertySetKey<AssignmentKey>"
//                    to be able to update <AssignmentKey> without re-adding.
//                    Upon automatic calculation, <AssignmentKey> contains reference ID hash
//                    of ordered property sets.
//
Procedure FillObjectPropertiesSets(Val Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey) Export
	If RefType = Type("CatalogRef.Partners") Then
		
		ListOfProperties = GetPropertySetsForPartners(Object.Client, Object.Competitor, Object.Vendor, Object.OtherRelations);
		
	ElsIf RefType = Type("CatalogRef.Products") And Not Object.IsFolder Then
		
		ListOfProperties = GetPropertySetsForProducts(Object);
		
	ElsIf RefType = Type("CatalogRef.ItemsCharacteristics") Then
		
		ListOfProperties = GetPropertySetsForProductCharacteristics(Object);
		
	ElsIf RefType = Type("CatalogRef.ItemsBatches") Then
		
		ListOfProperties = GetPropertySetsForSeriesOfProducts(Object);
		
	ElsIf RefType = Type("CatalogRef.Incidents") Then
		
		ListOfProperties = GetSetsOfPropertiesForIncidents(Object);		
	ElsIf RefType = Type("CatalogRef.Assets") Then
		
		ListOfProperties = GetPropertySetsForOperationObject(Object);
	ElsIf RefType = Type("CatalogRef.SubAssets") Then
		
		ListOfProperties = GetPropertySetsForExploitationObjectNode(Object);
		
	ElsIf RefType = Type("DocumentRef.ProductionOperation2_2") Then
		
		ListOfProperties = GetPropertySetsForProductionOperation(Object);
	Else
		
		Return;
		
	EndIf;
	
	For Each ListItem In ListOfProperties Do
		
		SetRow = PropertiesSets.Add();
		
		SetRow.Set 	   = ListItem.Value;
		SetRow.Title = ListItem.Presentation;
		
	EndDo;
	
EndProcedure

// SeePropertyManagerInternal.PropertiesListForObjectsKind.
Function PropertiesListForObjectsKind(ObjectsKind, Val PropertyKind) Export
	Return PropertyManagerInternal.PropertiesListForObjectsKind(ObjectsKind, PropertyKind);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR WORKING WITH THE PARTNERS DIRECTORY

// Returns a list of values consisting of sets of properties in the Partners directory.
//
// Parameters:
//  Client    			- Type - Boolean.
//  Competitor    		- Type - Boolean.
//  Vendor    		- Type - Boolean.
//  OtherRelations    	- Type - boolean.
//
// Returnable value:
//  Sets - List of values - Elements Of The Catalog Of "Sets of Additional Requestionsreferences".
//
Function GetPropertySetsForPartners(Client, Competitor, Vendor, OtherRelations) Export
	
	Sets = New ValueList;
	Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Partners_Overall"), NStr("vi = 'Chung cho tất cả bạn hàng';
																					|ru = 'Общие для всех партнеров';
																					|en = 'Common for all partners'; fa = 'Common for all partners';
																					|it = 'Comune per tutti i partner';
																					|pl = 'Wspólne dla wszystkich partnerów';
																					|tr = 'Tüm iş ortakları için paylaşımlı'"));
	
	If Client Then
		Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Partners_Customers"),    NStr("vi = 'Đối với khách hàng';
																							|ru = 'Для клиентов';
																							|en = 'For customers'; fa = 'For customers';
																							|it = 'Per i clienti';
																							|pl = 'Dla klientów';
																							|tr = 'Müşteriler için'"));
	EndIf;
	
	If Competitor Then
		Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Partners_Competitors"), NStr("vi = 'Đối với đối thủ cạnh tranh';
																							|ru = 'Для конкурентов';
																							|en = 'For competitors'; fa = 'For competitors';
																							|it = 'Per i concorrenti';
																							|pl = 'Dla konkurencji';
																							|tr = 'Rakipler için'"));
	EndIf;
	
	If Vendor Then
		Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Partners_Vendors"), NStr("vi = 'Đối với nhà cung cấp';
																						|ru = 'Для поставщиков';
																						|en = 'For vendors'; fa = 'For vendors';
																						|it = 'Per i fornitori';
																						|pl = 'Dla dostawców';
																						|tr = 'Tedarikçiler için'"));
	EndIf;
	
	If OtherRelations Then
		Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Partners_OtherItems"),     NStr("vi = 'Đối với người khác';
																								|ru = 'Для прочих';
																								|en = 'For other'; fa = 'For other';
																								|it = 'Per gli altri';
																								|pl = 'Dla innych';
																								|tr = 'Diğerleri için'"));
	EndIf;
	Return Sets;
	
EndFunction // Get a set of properties for partners()

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	TMPropertyManagement.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - object filling data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR WORKING WITH THE NOMENCLATURE REFERENCE

Function GetPropertySetsForProducts(Object)
	
	Sets = New ValueList;
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung ';
								|ru = 'Общие свойства';
								|en = 'Common properties'; fa = 'Common properties';
								|it = 'Proprietà in comune';
								|pl = 'Ogólne właściwości';
								|tr = 'Ortak özellikler'"));
	
	PropertiesSet = Common.ObjectAttributeValue(Object.ProductKind, "PropertiesSet");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính đối với dạng mặt hàng';
								|ru = 'Свойства для вида номенклатуры';
								|en = 'Properties for item kind'; fa = 'Properties for item kind';
								|it = 'Le proprietà per tipo di articolo';
								|pl = 'Właściwości dla rodzaju nomenklatury';
								|tr = 'Ürün türü için özellikler'"));
	Return Sets;
	
EndFunction

Function GetPropertySetsForProductCharacteristics(Object)
	
	Sets = New ValueList;
	
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung của đặc tính';
								|ru = 'Общие свойства характеристик';
								|en = 'Common variant properties'; fa = 'Common variant properties';
								|it = 'Le proprietà comuni per le caratteristiche';
								|pl = 'Ogólne właściwości cech';
								|tr = 'Ortak özellik özellikleri'"));
	
	If TypeOf(Object.Owner) = Type("CatalogRef.ItemKinds") Then
		
		PropertiesSet = Common.ObjectAttributeValue(Object.Owner, "CharacteristicsPropertySet");
		Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính của đặc tính đối với dạng mặt hàng';
									|ru = 'Свойства характеристик для вида номенклатуры';
									|en = 'Variant properties for item kind'; fa = 'Variant properties for item kind';
									|it = 'Le proprietà delle caratteristiche per tipo di articolo';
									|pl = 'Właściwości cech dla rodzaju nomenklatury';
									|tr = 'Ürün türü için özellik özellikleri'"));
		
	ElsIf TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Products.ProductKind AS ProductKind
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Owner);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			PropertiesSet = Common.ObjectAttributeValue(Selection.ProductKind, "CharacteristicsPropertySet");
			Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính của đặc tính đối với mặt hàng';
										|ru = 'Свойства характеристик для номенклатуры';
										|en = 'Variant properties for product'; fa = 'Variant properties for product';
										|it = 'Le proprietà delle caratteristiche per l''articolo';
										|pl = 'Właściwości cech dla nomenklatury';
										|tr = 'Ürün türü için özellik özellikleri'"));
		EndIf;
		
	EndIf;
	
	Return Sets;
	
EndFunction // Get a set of properties for the Characteristic Nomenclature()

Function GetPropertySetsForSeriesOfProducts(Object)
	
	Sets = New ValueList;
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung ';
								|ru = 'Общие свойства';
								|en = 'Common properties'; fa = 'Common properties';
								|it = 'Proprietà in comune';
								|pl = 'Ogólne właściwości';
								|tr = 'Ortak özellikler'"));
	
	PropertiesSet = Common.ObjectAttributeValue(Object.ProductKind, "BatchPropertySet");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính đối với khuôn mẫu sê-ri mặt hàng';
								|ru = 'Свойства для шаблона серий номенклатуры';
								|en = 'Properties for item batch template'; fa = 'Properties for item batch template';
								|it = 'Le proprietà per il modello delle serie di articolo';
								|pl = 'Właściwości dla szablonu serii nomenklatury';
								|tr = 'Ürün serileri şablonu için özellikler'"));
	Return Sets;
	
EndFunction // Get a Set of properties for Nomenclature()
////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR WORKING WITH THE OBJECTS OF OPERATION DIRECTORY

Function GetPropertySetsForOperationObject(Object)
	
	Sets = New ValueList;
	
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_Assets_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung của các đối tượng vận hành';
								|ru = 'Общие свойства объектов эксплуатации';
								|en = 'Common asset properties'; fa = 'Common asset properties';
								|it = 'Le proprietà comuni per gli oggetti di esercizio';
								|pl = 'Ogólne właściwości obiektów obsługi';
								|tr = 'Kullanılan nesnelerin ortak özellikleri'"));
	GetSetsOfPropertiesForObjectClass(Object, Sets);
	Return Sets;
	
EndFunction

Function GetPropertySetsForExploitationObjectNode(Object)
	
	Sets = New ValueList;
	
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_SubAssets_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung của các nút';
								|ru = 'Общие свойства узлов';
								|en = 'Node common properties'; fa = 'Node common properties';
								|it = 'Le proprietà comuni per i nodi';
								|pl = 'Ogólne właściwości węzłów';
								|tr = 'Alt varlıkların ortak özellikleri'"));
	GetSetsOfPropertiesForObjectClass(Object, Sets);
	
	Return Sets;
	
EndFunction

Procedure GetSetsOfPropertiesForObjectClass(Object, Sets)
	
	PropertiesSets = Catalogs.MaintenanceSchemes.GetPropertySets(Object.Class);
	Sets.Add(PropertiesSets.PassportData, NStr("vi = 'Thuộc tính theo bảng phân loại';
												|ru = 'Свойства по классификации';
												|en = 'Properties by classification'; fa = 'Properties by classification';
												|it = 'Le proprietà per la classifica';
												|pl = 'Właściwości po klasyfikacji';
												|tr = 'Sınıflara göre özellikler'"));
	
EndProcedure

Function GetPropertySetsForProductionOperation(Object)
	
	Sets = New ValueList;
	
	PropertiesSet = PropertyManager.PropertiesSetByName("Document_ProductionOperation2_2_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung ';
								|ru = 'Общие свойства';
								|en = 'Common properties'; fa = 'Common properties';
								|it = 'Proprietà in comune';
								|pl = 'Ogólne właściwości';
								|tr = 'Ortak özellikler'"));
	
	If Not Object.OperationKind.IsEmpty() Then
		PropertiesSet = Common.ObjectAttributeValue(Object.OperationKind, "PropertiesSet");
		Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính đối với dạng giao dịch';
									|ru = 'Свойства для вида операции';
									|en = 'Property for operation type'; fa = 'Property for operation type';
									|it = 'Le proprietà per tipo di operazione';
									|pl = 'Właściwości dla rodzaju operacji';
									|tr = 'İşlem türü için özellikler'"));
	EndIf;
	
	Return Sets;
	
EndFunction
////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR WORKING WITH THE INCIDENTSCatalog

Function GetSetsOfPropertiesForIncidents(Object)
	
	Sets = New ValueList;
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_Incidents_Overall");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính chung';
								|ru = 'Общие свойства';
								|en = 'Common properties'; fa = 'Common properties';
								|it = 'Proprietà in comune';
								|pl = 'Ogólne właściwości';
								|tr = 'Ortak özellikler'"));
	
	PropertiesSet = Common.ObjectAttributeValue(Object.IncidentKind, "PropertiesSet");
	Sets.Add(PropertiesSet, NStr("vi = 'Thuộc tính đối với dạng mặt hàng';
								|ru = 'Свойства для вида номенклатуры';
								|en = 'Properties for item kind'; fa = 'Properties for item kind';
								|it = 'Le proprietà per tipo di articolo';
								|pl = 'Właściwości dla rodzaju nomenklatury';
								|tr = 'Ürün türü için özellikler'"));
	Return Sets;
	
EndFunction    

#EndRegion