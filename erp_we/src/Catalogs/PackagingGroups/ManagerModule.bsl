#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("UnitOfMeasure");
	
	Return Result;

EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	#Region BasicUnitsOfMeasure
	Item = Items.Add();
	Item.PredefinedDataName = "BasicUnitsOfMeasure";
	Item.Description = NStr("vi = 'Đơn vị tính cơ sở';
							|ru = 'Базовые единицы измерения';
							|en = 'Basic units of measure'; fa = 'Basic units of measure';
							|it = 'Unità di misura principali';
							|pl = 'Podstawowe jednostki miary';
							|tr = 'Temel ölçü birimleri'", DefaultLanguageCode);
	#EndRegion

	#Region SpecialForItem
	Item = Items.Add();
	Item.PredefinedDataName = "SpecialForItem";
	Item.Description = NStr("vi = 'Bộ sản phẩm riêng đối với mặt hàng';
							|ru = 'Индивидуальный набор для номенклатуры';
							|en = 'Individual set for products'; fa = 'Individual set for products';
							|it = 'Il set individuale per l''articolo';
							|pl = 'Indywidualny zestaw dla nomenklatury';
							|tr = 'Öğe için özelleştirilmiş küme'", DefaultLanguageCode);
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.PackagingGroups - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion 

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.PackingSetsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf
#EndIf
