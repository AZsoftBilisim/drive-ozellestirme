
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

	#Region VarianceOnDimensionalGoodsShipment
	Item = Items.Add();
	Item.PredefinedDataName = "VarianceOnDimensionalGoodsShipment";
	Item.Description = NStr("vi = 'Sai lệch trên lô hàng đo';
							|ru = 'Отклонение при отгрузке мерных товаров';
							|en = 'Variance on measured goods shipment'; fa = 'Variance on measured goods shipment';
							|it = 'Disabilitazione alla spedizione di merci misurate';
							|pl = 'Odchylenie podczas wysyłki towarów miarowych';
							|tr = 'Ölçümü yapılan malların sevkiyatında sapma'", Common.DefaultLanguageCode());
	Item.CanBeSpecifiedByCustomer = False;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.ReasonsForSaleOrderCancellation - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

#EndIf
