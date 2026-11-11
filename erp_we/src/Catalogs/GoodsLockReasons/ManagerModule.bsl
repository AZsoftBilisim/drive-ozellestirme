#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array of String - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.PredefinedDataName = "InputQualityControlOfGoods";
	Item.Description = NStr("vi = 'Kiểm soát chất lượng đầu vào';
							|ru = 'Входной контроль качества';
							|en = 'Incoming quality control'; fa = 'Incoming quality control';
							|it = 'Incoming quality control';
							|pl = 'Incoming quality control';
							|tr = 'Giriş kalite kontrolü'", Common.DefaultLanguageCode());
	Item.ToScheduleGoodsUnlock = True;
	Item.Code = "000000001";
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.GoodsLockReasons.FillItemsWithInitialData";
	Handler.Version = "11.5.27.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a2e53b58-e28f-4db6-b8ea-ccc9c53b7225");
	Handler.UpdateDataFillingProcedure = "Catalogs.GoodsLockReasons.RegisterPredefinedItemsToUpdate";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật các phần tử định trước.';
							|ru = 'Обновление предопределенных элементов.';
							|en = 'Update predefined items.'; fa = 'Update predefined items.';
							|it = 'Update predefined items.';
							|pl = 'Update predefined items.';
							|tr = 'Önceden tanımlanmış öğelerin güncellenmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.GoodsLockReasons.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.GoodsLockReasons.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.GoodsLockReasons.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterPredefinedItemsToUpdate(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(
		Parameters,
		Metadata.Catalogs.GoodsLockReasons);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters) Export
	
	InfobaseUpdate.FillItemsWithInitialData(
		Parameters,
		Metadata.Catalogs.GoodsLockReasons);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf