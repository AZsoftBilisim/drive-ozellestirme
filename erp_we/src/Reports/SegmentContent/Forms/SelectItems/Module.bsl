#Region Variables

&AtClient
Var CachedValues;//used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Characteristic);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Products);
	StringStructure.Insert("Characteristic", Characteristic);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(ThisForm, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)

	If Products.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra mặt hàng.';
												|ru = 'Не указана номенклатура.';
												|en = 'Items are not specified.'; fa = 'Items are not specified.';
												|it = 'Articoli non indicati.';
												|pl = 'Nie określono nomenklatury.';
												|tr = 'Öğe belirtilmedi.'"),
		                                                  ,
		                                                  "Products");
		Return;
	EndIf;
	
	If ItemVariantsAreUsed And Characteristic.IsEmpty() Then
	
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra đặc tính.';
												|ru = 'Не указана характеристика.';
												|en = 'Variant is not specified.'; fa = 'Variant is not specified.';
												|it = 'Caratteristica non indicata.';
												|pl = 'Nie określono charakterystykę.';
												|tr = 'Varyant belirtilmedi.'"),
		                                                  ,
		                                                  "Characteristic");
		Return;
	
	EndIf;
	
	Close(New Structure("Products, Characteristic", Products, Characteristic));

EndProcedure

#EndRegion
