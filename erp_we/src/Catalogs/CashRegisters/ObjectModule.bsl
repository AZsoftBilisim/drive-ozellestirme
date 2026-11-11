#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Warehouse = SettingsValueCached.GetDefaultRetailWarehouse(Warehouse);
	Owner = SettingsValueCached.GetDefaultOrganization(Owner);
	If Not ValueIsFilled(CashCurrency) Then
		CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Owner);
	EndIf;
	
	If Not TMCommonUse.UsePeripherals() Then
		UseWithoutConnectingPeripherals = True;
	EndIf;
	
	CashServer.ProcessingCatalogFilling(ThisObject);

	If Not ValueIsFilled(Warehouse) And GetFunctionalOption("UseSeveralWarehouses") = False Then
		
		Query = New Query(
		"SELECT ALLOWED TOP 2
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses");
		
		If Query.Execute().Select().Count() = 2 Then
			Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Trong cơ sở thông tin đã nhập nhiều kho,
			                             |Hãy bật tùy chọn ""Sử dụng nhiều kho""!';
			                             |ru = 'Не удалось заполнить поле ""Склад"". В информационной базе введено несколько складов,
			                             |Включите функциональную опцию ""Использовать несколько складов""!';
			                             |en = 'Cannot fill in the ""Warehouse"" field. There are several warehouses entered into the infobase.
			                             |Enable functional option ""Use several warehouses"".'; fa = 'Cannot fill in the ""Warehouse"" field. There are several warehouses entered into the infobase.
			                             |Enable functional option ""Use several warehouses"".';
			                             |it = 'Non è stato possibile compilare il campo ""Magazzino"". Nel database informatico sono presenti multipli magazzini,
			                             |Abilitate l''impostazione funzionale ""Utilizzare più magazzini""!';
			                             |pl = 'Wypełnianie pola ""Magazyn"" nie powiodło się. W bazie informacyjnej wprowadzono kilka magazynów,
			                             |Włącz opcję funkcjonalną ""Używaj kilku magazynów""!';
			                             |tr = 'Ambar alanı doldurulamadı. Infobase''e birden fazla ambar girildi,
			                             |""Birden fazla ambar kullan"" işlevsel seçeneğini etkinleştir!'");
		Else
			AnyWarehouse = SettingsValueCached.GetDefaultWarehouse();
			If ValueIsFilled(AnyWarehouse) Then
				Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Đối với kho của doanh nghiệp chỉ có thể lập các giao dịch bán buôn.
				                             |Để lập các giao dịch bán lẻ, hãy tạo kiểu kho: Bán buôn, bán lẻ.';
				                             |ru = 'Не удалось заполнить поле ""Склад"". На склад предприятия возможно оформление только операций оптовой продажи.
				                             |Для оформления розничных операций установите тип склада: Оптово-розничный.';
				                             |en = 'Cannot fill in the ""Warehouse"" field. It is only possible to register wholesale operations at the company''s warehouse.
				                             |To register retail operations, set the warehouse type: Wholesale and retail.'; fa = 'Cannot fill in the ""Warehouse"" field. It is only possible to register wholesale operations at the company''s warehouse.
				                             |To register retail operations, set the warehouse type: Wholesale and retail.';
				                             |it = 'Non è stato possibile compilare il campo ""Magazzino"". Solo le operazioni all''ingrosso sono possibili nel magazzino dell''azienda.
				                             |Per organizzare le operazioni di vendita al dettaglio, impostare il tipo di magazzino: Ingrosso-dettaglio.';
				                             |pl = 'Wypełnianie pola ""Magazyn"" nie powiodło się. W magazynie przedsiębiorstwa można rejestrować tylko operacje sprzedaży hurtowej.
				                             |W celu rejestracji operacji detalicznych ustaw typ magazynu: Hurtowo-detaliczny.';
				                             |tr = 'Ambar alanı doldurulamadı. İşletme ambarında sadece toptan satış işlemleri kaydedilebilir.
				                             |Perakende operasyonlarını kaydetmek için ambar türünü ayarla: Toptan-perakende.'");
			Else
				Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Có thể là, trong cơ sở thông tin chưa điền kho bãi nào cả';
							|ru = 'Не удалось заполнить поле ""Склад"". Возможно, в информационной базе не введено ни одного склада';
							|en = 'Cannot fill in the ""Warehouse"" field. Possibly, there are no warehouses entered into the infobase.'; fa = 'Cannot fill in the ""Warehouse"" field. Possibly, there are no warehouses entered into the infobase.';
							|it = 'Non è stato possibile compilare il campo ""Magazzino"". Probabilmente nel database informatico non è stato immesso nessun magazzino';
							|pl = 'Wypełnianie pola ""Magazyn"" nie powiodło się. Być może w bazie informacyjnej nie wprowadzono żadnego magazynu';
							|tr = 'Ambar alanı doldurulamadı. Infobase''te herhangi bir ambar girilmemiş olabilir.'");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If CashRegisterType = Enums.CashRegisterTypes.MobileCashRegister Then
		
		UseWithoutConnectingPeripherals = False;
		Peripherals               = Undefined;
		AutomaticCashCollection               = False;
		
	ElsIf CashRegisterType = Enums.CashRegisterTypes.CashRegisterOffline Then
		
		UseWithoutConnectingPeripherals = False;
		AutomaticCashCollection               = False;
		Warehouse                                  = Undefined;
		
	EndIf;
	
	If CashRegisterType <> Enums.CashRegisterTypes.FiscalCashRegisters And ItinerantTrade Then
		ItinerantTrade = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralCashRegisters") Then
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT TOP 1
		|	CashRegisters.Ref
		|FROM
		|	Catalog.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.Ref <> &Ref");
		
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() Then
			Constants.UseSeveralCashRegisters.Set(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If ValueIsFilled(Warehouse) Then
		WarehouseStore = Common.ObjectAttributeValue(Warehouse, "WarehouseStore");
		If WarehouseStore <> Enums.TypesOfWarehouses.RetailStore Then
			
			ErrorText = NStr("vi = 'Hãy chỉ định kho bãi có kiểu %1';
							|ru = 'Укажите склад с типом %1';
							|en = 'Specify a warehouse with the %1 type'; fa = 'Specify a warehouse with the %1 type';
							|it = 'Укажите склад с типом %1';
							|pl = 'Specify a warehouse with the %1 type';
							|tr = '%1 türündeki ambarları belirtin'");
			ErrorText = StrTemplate(ErrorText, Enums.TypesOfWarehouses.RetailStore);
			
			Common.MessageToUser(ErrorText, ThisObject, "Warehouse", , Cancel);
			
		EndIf;
	ElsIf CashRegisterType = Enums.CashRegisterTypes.CashRegisterOffline Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	DetailsForRegistry = New Structure;
	DetailsForRegistry.Insert("DeletionMark");
	DetailsForRegistry.Insert("Description");
	DetailsForRegistry.Insert("Owner", "Organization");
	
	Result.Insert("Catalog.DocumentRegistryKeys", DetailsForRegistry);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf