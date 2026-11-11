#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the element of the guide is the key dimension accounting of an item if it is not, it will be created
//
// Parameters:
//	AnalyticsParameters - QueryResultSelection, Structure - the values of the fields used to create the key:
//		* Products - CatalogRef.Products
//		* Characteristic - CatalogRef.ItemsCharacteristics
//		* Series - CatalogRef.ItemsBatches
//		* StorageLocation - CatalogRef
//		* Purpose - CatalogRef.Assignments
//		* ProductCostElement - CatalogRef.ProductCostElements
//
// Returns:
//	CatalogRef.InventoryLocationAttributeKeys
//
Function AnalyticsKeyValue(AnalyticsParameters) Export

	RecordSet = GetRecordSet(AnalyticsParameters);
	
	RecordSet.Read();
	
	If RecordSet.Count() > 0
		And Not ValueIsFilled(RecordSet[0].DimensionKey) Then
		RecordSet.Clear();
		RecordSet.Write();
	EndIf;
	
	If RecordSet.Count() > 0
		And ValueIsFilled(RecordSet[0].DimensionKey) Then
		Result = RecordSet[0].DimensionKey;
	Else
		Result = CreateAnalyticsKey(AnalyticsParameters);
	EndIf;
	
	Return Result;

EndFunction

// Creates a reference element-the accounting Analytics key.
//
// Parameters:
//	AnalyticsParameters - QueryResultSelection, Structure - the values of the fields used to create the key:
//		* Products - CatalogRef.Products
//		* Characteristic - CatalogRef.ItemsCharacteristics
//		* Series - CatalogRef.ItemsBatches
//		* StorageLocation - CatalogRef
//		* Purpose - CatalogRef.Assignments
//		* ProductCostElement - CatalogRef.ProductCostElements
//	RecordingWhenUpdatingInformationSecurity - Boolean
//
// Returns:
//	CatalogRef.InventoryLocationAttributeKeys
//
Function CreateAnalyticsKey(AnalyticsParameters, RecordingWhenUpdatingInformationSecurity = False) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = GetRecordSet(AnalyticsParameters);
	KeyPresentation = "";
	HasExternalTransaction = TransactionActive();
	
	BeginTransaction(); // Creating a new analytics key.
	Try
		SetRow = RecordSet[0];
		
		KeyPresentation = DimensionKeyName(SetRow);
		
		CatalogObject = Catalogs.InventoryLocationAttributeKeys.CreateItem();
		CatalogObject.Description = KeyPresentation;
		FillPropertyValues(CatalogObject, SetRow, "Products, Characteristic, Series, StorageLocation, Purpose, ProductCostElement");
		
		If TypeOf(SetRow.StorageLocation) = Type("CatalogRef.Warehouses") Then
			
			CatalogObject.StorageType = Enums.StorageLocationTypes.Warehouse;
			CatalogObject.WarehouseArea = SetRow.StorageLocation;
			
		ElsIf TypeOf(SetRow.StorageLocation) = Type("CatalogRef.CounterpartyContracts") Then
			
			AgreementFields = Common.ObjectAttributesValues(SetRow.StorageLocation, "Partner, Counterparty");
			
			CatalogObject.StorageType = Enums.StorageLocationTypes.CounterpartyContract;
			CatalogObject.Contract = SetRow.StorageLocation;
			
			CatalogObject.Partner = AgreementFields.Partner;
			CatalogObject.Counterparty = AgreementFields.Counterparty;
			
		ElsIf TypeOf(SetRow.StorageLocation) = Type("CatalogRef.Companies") Then
			
			CatalogObject.StorageType = Enums.StorageLocationTypes.Organization;
			CatalogObject.Organization = SetRow.StorageLocation;
			
		ElsIf TypeOf(SetRow.StorageLocation) = Type("CatalogRef.Partners") Then
			
			CatalogObject.StorageType = Enums.StorageLocationTypes.Partner;
			CatalogObject.Partner = SetRow.StorageLocation;
			
		ElsIf TypeOf(SetRow.StorageLocation) = Type("CatalogRef.BusinessStructure") Then
			
			CatalogObject.StorageType = Enums.StorageLocationTypes.Department;
			CatalogObject.Department = SetRow.StorageLocation;
			
		EndIf;
		
		If RecordingWhenUpdatingInformationSecurity Then
			InfobaseUpdate.WriteObject(CatalogObject);
		Else
			CatalogObject.Write();
		EndIf;
		
		SetRow.DimensionKey = CatalogObject.Ref;
		
		If RecordingWhenUpdatingInformationSecurity Then
			InfobaseUpdate.WriteRecordSet(RecordSet, False, True);
		Else
			RecordSet.Write(False);
		EndIf;
		
		Result = CatalogObject.Ref;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		EventName = NStr("ru = 'Создание ключа аналитики учета номенклатуры';
						|vi = 'Создание ключа аналитики учета номенклатуры';
						|en = 'Создание ключа аналитики учета номенклатуры'; fa = 'Создание ключа аналитики учета номенклатуры';
						|it = 'Создание ключа аналитики учета номенклатуры';
						|pl = 'Создание ключа аналитики учета номенклатуры';
						|tr = 'Создание ключа аналитики учета номенклатуры'");
		
		MessageText = NStr("ru = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2';
							|vi = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2';
							|en = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2'; fa = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2';
							|it = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2';
							|pl = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2';
							|tr = 'Не удалось создать ключ аналитики учета номеклатуры ""%1"" по причине: %2'");
		MessageText = StrTemplate(MessageText,
									KeyPresentation,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
		
		If HasExternalTransaction Then
			Raise;
		Else
			// during key initialization, this key has already been created in the IB by another session.
			RecordSet.Read();
			If RecordSet.Count() = 0 Then // the record was not created due to an error filling in the fields.
				Raise;
			Else
				Result = RecordSet[0].DimensionKey;
			EndIf;
		EndIf;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Returns the parameters of the key generation Analytics. Used in update handlers.
// Returns:
//	Structure - The structure contains the fields: There are processed keys, changed analytics, create new keys.
Function ParametersForFillingInAnalyticsKeys() Export
	Return New Structure("ChangedAnalytics,CreateInKeys", False, True);
EndFunction

// Fills in the inventory analyticaccount Field in the collection that contains the item, characteristic, series, warehouse, and destination.
// Accounting locations and field names for accounting locations are interpreted as follows:
//	for keys, except Arbitrary:
//		if the field name is specified (there is a key in the structure) and the value is filled in, then select data from this field.;
//		if the field name is specified, but the value is not filled in ("" or Undefined), then the data is always collected from accounting locations;
//		if the field name is not specified, then the key is filled in Randomly;
//	for the Custom key:
//		if the field name value is filled in, all item types that are not mentioned in other keys select
//		data from this collection field. if the value is not set in the collection field, then the data is set from accounting locations;
//		if the field value is not filled in, the data is always set from accounting locations;
//
// Parameters:
//
//	Collection - TabularSection - The collection where the item accounting analysis is filled in.
//
//	PlacesOfAccounting - Structure - Places where item types are registered:
//		* Arbitrary - CatalogRef.Warehouses, CatalogRef.BusinessStructure - [, Product, Multi-turnover, Service, Work]},
//			an Arbitrary key is required. Sets the values of the general accounting locations by item type and determines how the Warehouse field is filled in in analytics
//			if there is no data to fill in in the collection (there are no fields or the field is not filled in).
//			for an example, see the method of place accounting(...)
//		* Work_5 - CatalogRef.Warehouses, CatalogRef.BusinessStructure - place of work registration.
//
//	FieldsNames - Structure - contains the real names of the collection fields for getting and generating Analytics.
//		contains two sections, if the key value is Undefined, the field name is taken from the name of the key.
//		identification section {Nomenclature, Characteristic, analyticaccounts of Nomenclature [, Statusquastionseries, Series]},
//			keys for defining series fields are optional, the use of series is determined by the Statusquastionseries field.
//		section place of registration {Arbitrary [, Commodity, Mnogokratnaya, Service, Job]}, a Random key is required.
//		to be filled by Imunoprecipitation(...)
//			("Nomenclature, Characteristics, Series, Purpose, Analyticallaboratory, Arbitrary Work,"
//			"Item", "Feature", "Series", "Appointment", "Of Analyticallaboratory", "", "")
//	Add key - Boolean-Used in update handlers, when working with the tab. part of the Viewspaces.
//	
//	FillParameters - see the Key Analysis parameterfill method()
//
// Example 1:
//	Place of accounting = Registers of entries.Analyticaccounts of the nomenclature.Place of accounting(
//		This is an object.Economic operation, this is an object.Warehouse Sender, Undetermined, Undetermined);
//	Field names = Registers of entries.Analyticaccounts of the nomenclature.Namepolecollectionpol Silence();
//	The name of the fields.StatusUkazaniyAsery = "Statusukazaniyasery Sender";
//	Registers of entries.Analyticaccounts of the nomenclature.Fill in Collections (Products, accounting places, Field names);
//
// Example 2:
//	Place of accounting = A New Structure("Arbitrary, Work", this is an object.Partner, this is an object.Division)
//	Registers of entries.Analyticaccounts of the nomenclature.Fill in Collections (Products, places of accounting);
//
Procedure FillInCollection(Collection, PlacesOfAccounting, FieldsNames = Undefined, FillParameters = Undefined) Export
	SetPrivilegedMode(True);
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInAnalyticsKeys();
	EndIf;
	
	If FieldsNames = Undefined Then
		FieldsNames = DefaultCollectionFieldNames();
	EndIf;
	Query = New Query(TextOfAnalyticsKeyValueInCollection(FieldsNames));
	Query.SetParameter("Collection", Collection);
	Query.SetParameter("PlacesWhereGoodsAreRegistered", ?(PlacesOfAccounting.Property("OwnGoods"), PlacesOfAccounting.OwnGoods, PlacesOfAccounting.Arbitrary));
	Query.SetParameter("PlacesOfAccountingMultiTurnPackaging", ?(PlacesOfAccounting.Property("ReusablePackage"), PlacesOfAccounting.ReusablePackage, PlacesOfAccounting.Arbitrary));
	Query.SetParameter("PlacesOfAccountingService", ?(PlacesOfAccounting.Property("OperationService"), PlacesOfAccounting.OperationService, PlacesOfAccounting.Arbitrary));
	Query.SetParameter("PlacesOfAccountingWork", ?(PlacesOfAccounting.Property("Work_5"), PlacesOfAccounting.Work_5, PlacesOfAccounting.Arbitrary));
	
	If ValueIsFilled(FieldsNames.Purpose)
		And TypeOf(FieldsNames.Purpose) = Type("Structure")
		And FieldsNames.Purpose.Property("Value") Then
		Query.SetParameter("Purpose", FieldsNames.Purpose.Value);
	EndIf;
	
	Query.TempTablesManager = New TempTablesManager;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.ItemsLocationAttributes) Then
			If FillParameters.CreateInKeys Then
				DimensionKey = AnalyticsKeyValue(Selection);
			Else
				ExceptionText = NStr("vi = 'Lỗi khi điền khóa trong bộ sưu tập: có các chỉ số mà theo đó còn chưa tạo khóa.';
									|ru = 'Ошибка при заполнении ключей в коллекции: есть аналитики, по которым ключи еще не созданы.';
									|en = 'An error occurred while populating keys in collection: there are dimensions for which keys are not created.'; fa = 'An error occurred while populating keys in collection: there are dimensions for which keys are not created.';
									|it = 'Errore di compilazione delle chiavi nella collezione: ci sono analitiche per le quali le chiavi non sono state ancora create.';
									|pl = 'Błąd podczas wypełniania kluczy w kolekcji: są analitycy, dla których klucze nie zostały jeszcze utworzone.';
									|tr = 'Koleksiyondaki anahtarları doldururken hata: anahtarları henüz oluşturulmayan boyutlar var.'");
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,
					Metadata.Catalogs.InventoryLocationAttributeKeys,
					,
					ExceptionText);
				Raise ExceptionText;
			EndIf;
		Else
			DimensionKey = Selection.ItemsLocationAttributes;
		EndIf;
		
		Collection[Selection.IndexOf][FieldsNames.ItemsLocationAttributes] = DimensionKey;
		
		FillParameters.ChangedAnalytics = True;
	EndDo;
	
EndProcedure

// Creates a structure that defines which accounting locations to use for different item types
// when filling in the analysis keys in the product tabs.
//
// Parameters:
//	Operation - EnumRef.BusinessTransactions,
//		Enum link.Types Of Storage-Households.the operation of the document.
//	Warehouse - CatalogRef.Warehouses - The warehouse that the key is generated for.
//	Department - CatalogRef.BusinessStructure - The division that the key is generated for.
//	Partner - CatalogRef.Partners - The partner that the key is generated for.
//	Contract - CatalogRef.CounterpartyContracts - The agreement that the key is generated for.
//
// Returns:
//	Structure - LongDesc:
//	* Arbitrary - Arbitrary - place the account in default.
//	* Work_5 - CatalogRef.BusinessStructure - place of registration for work.
//
Function PlacesOfAccounting(Operation, Warehouse, Department, Partner, Contract = Undefined) Export
	
	AccountingWarehouse = ?(Warehouse = Undefined, Catalogs.Warehouses.EmptyRef(), Warehouse);
	AccountingDivision = ?(Department = Undefined, Catalogs.BusinessStructure.EmptyRef(), Department);
	AccountingPartner = ?(Partner = Undefined, Catalogs.Partners.EmptyRef(), Partner);
	AccountingAgreement = ?(Contract = Undefined, Catalogs.CounterpartyContracts.EmptyRef(), Contract);
	
	PlacesOfAccounting = New Structure("Arbitrary, Work_5");
	
	UsePartner =
		(Operation = Enums.BusinessTransactions.ConsignmentReportFromCustomer)
		Or (Operation = Enums.BusinessTransactions.ConsignmentReportToVendor)
		Or (Operation = Enums.BusinessTransactions.ReturnablePackagingRedemptionByCustomer)
		Or (Operation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
		Or (Operation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers)
		Or (Operation = Enums.BusinessTransactions.DeliveryForPrincipal);
	
	UseContract = 
		(Operation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.ImportGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
		Or (Operation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
		Or (Operation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
		Or (Operation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
		Or (Operation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale)
		Or (Operation = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense)
		Or (Operation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor)
		Or (Operation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor)
		Or (Operation = Enums.BusinessTransactions.RedemptionOfGoodsByCustodian)
		Or (Operation = Enums.BusinessTransactions.ReturnFromCustodian)
		Or (Operation = Enums.BusinessTransactions.MisgradingOfGoodsAtCustodian)
		Or (Operation = Enums.BusinessTransactions.DamageAtCustodian)
		
		Or (Operation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5)
		Or (Operation = Enums.BusinessTransactions.ProductionByToller2_5)
		Or (Operation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5)
		Or (Operation = Enums.BusinessTransactions.TransferToToller2_5)
		Or (Operation = Enums.BusinessTransactions.ReceiptFromToller2_5)
		Or (Operation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5)
		Or (Operation = Enums.BusinessTransactions.GoodsWriteOffAtToller)
		Or (Operation = Enums.BusinessTransactions.RedemptionOfGoodsByToller)
		Or (Operation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller)
		Or (Operation = Enums.BusinessTransactions.DamageAtToller)
		
		Or Operation = Enums.BusinessTransactions.RedemptionOfProviderGoods
		Or Operation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Operation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		
		Or (Operation = Enums.BusinessTransactions.SalesViaCommissionAgent)
		Or (Operation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		Or (Operation = Enums.BusinessTransactions.TransferOfTitleToGoods)
		Or (Operation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
		Or (Operation = Enums.StorageLocationTypes.CounterpartyContract)
		Or (Operation = Enums.BusinessTransactions.DeliveryForPrincipal)
		Or (Operation = Enums.BusinessTransactions.OBEntryShippedGoods);
	
	UseADivision = (Operation = Enums.StorageLocationTypes.Department);
	
	PlacesOfAccounting.Arbitrary = AccountingWarehouse;
	If UsePartner Then
		PlacesOfAccounting.Arbitrary = AccountingPartner;
	ElsIf UseContract Then
		PlacesOfAccounting.Arbitrary = AccountingAgreement;
	ElsIf UseADivision Then
		PlacesOfAccounting.Arbitrary = AccountingDivision;
	EndIf;
	PlacesOfAccounting.Work_5 = AccountingDivision;
	
	Return PlacesOfAccounting;
EndFunction

// Returns the structure of fields for selecting information from the collection for generating item accounting Analytics.
//
// Returns:
//	Structure - contains the real names of the collection fields for obtaining and generating analytics.
//		contains two sections, if the key value is Undefined, then the field name should be taken from the key name.
//		identification section {Nomenclature, Characteristics, analyticscountainment, statusquest series, Series,
//		Assignment},
//			all keys are set.
//		section of the place of accounting {Arbitrary, [Product, Returnable, Service, ] Work}, the keys Arbitrary and Work are set.
//			the details of this section should contain the names of the columns of the collection, from where it is necessary to take values for the same
//			types of nomenclature.
//
Function DefaultCollectionFieldNames() Export
	
	FieldsNames = New Structure();
	FieldsNames.Insert("Products", "Products");
	FieldsNames.Insert("Characteristic", "Characteristic");
	FieldsNames.Insert("ItemsLocationAttributes", "ItemsLocationAttributes");
	FieldsNames.Insert("BatchesIndicationStatus", "BatchesIndicationStatus");
	FieldsNames.Insert("Series", "Series");
	FieldsNames.Insert("Purpose", "Purpose");
	FieldsNames.Insert("ProductCostElement", "");
	FieldsNames.Insert("Arbitrary", "");
	FieldsNames.Insert("Work_5", "");
	
	Return FieldsNames;
EndFunction

// Returns the structure of fields for selecting information from the collection for generating item accounting Analytics.
//
// Returns:
//	Structure - contains the real names of the collection fields for obtaining and generating analytics.
//
Function NamesOfFieldsInDefaultCollection() Export
	
	FieldsNames = New Structure();
	FieldsNames.Insert("ItemsLocationAttributes", "ItemsLocationAttributes");
	FieldsNames.Insert("ProductAccountingAnalyticsToFillIn", "ItemsLocationAttributes");
	FieldsNames.Insert("Products", "");
	FieldsNames.Insert("Characteristic", "");
	FieldsNames.Insert("Series", "");
	FieldsNames.Insert("Warehouse", "");
	FieldsNames.Insert("StorageLocation", "");
	FieldsNames.Insert("ProductCostElement", "");
	FieldsNames.Insert("InventoryOwnerAttribute", "InventoryOwnerAttribute");
	
	Return FieldsNames;
EndFunction

// The function returns the name of the analytics key.
//
// Parameters:
//	RecordManager - InformationRegisterRecordManager.ItemsLocationAttributes
//                 - CatalogObject.InventoryLocationAttributeKeys - A completed object with the necessary fields to generate the name of the analytics key.
//
// Returns:
//	String
//
Function DimensionKeyName(RecordManager) Export
	
	// We will get the name of the analytics key in the main language, taking into account the multilingual nature of the directories
	Return TrimAll(Common.ObjectAttributeValue(RecordManager.Products, "Description")) + "; " 
		+ ?(ValueIsFilled(RecordManager.Characteristic), TrimAll(Common.ObjectAttributeValue(RecordManager.Characteristic, "Description")) + "; ", "")
		+ ?(ValueIsFilled(RecordManager.Series), TrimAll(RecordManager.Series) + "; ", "")
		+ ?(ValueIsFilled(RecordManager.Purpose), TrimAll(RecordManager.Purpose) + "; ", "")
		+ ?(ValueIsFilled(RecordManager.ProductCostElement), TrimAll(Common.ObjectAttributeValue(RecordManager.ProductCostElement, "Description")) + "; ", "")
		+ TrimAll(RecordManager.StorageLocation);

EndFunction

#EndRegion

#Region Private

#Region Other

Function GetRecordSet(AnalyticsParameters)
	
	// The analytics parameters may not have all the properties
	StructureOfAnalytics = New Structure("Products, Characteristic, Series, StorageLocation, Purpose, ProductCostElement");
	
	FillPropertyValues(StructureOfAnalytics, AnalyticsParameters);
	
	If StructureOfAnalytics.StorageLocation = Undefined 
		And CommonClientServer.HasAttributeOrObjectProperty(AnalyticsParameters, "Warehouse") Then
		
		// The calling code can transmit the storage location in the "Warehouse" field
		StructureOfAnalytics.StorageLocation = AnalyticsParameters.Warehouse;
		
	EndIf;
	
	If Not ValueIsFilled(StructureOfAnalytics.Products) Then
		Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: chưa chỉ ra mặt hàng.';
						|ru = 'Ошибка при получении набора регистра сведений %Couples1%: не указана номенклатура.';
						|en = 'An error occurred while retrieving a set of data from information register %Couples1%: no products are specified.'; fa = 'An error occurred while retrieving a set of data from information register %Couples1%: no products are specified.';
						|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: articoli non indicati.';
						|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: nie podano nomenklatury.';
						|tr = '%Couples1% bilgi kaydı kümesi alınırken hata oluştu: öğe belirtilmedi.'");
		Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
		
		Raise Template1 ;
	Else
		
		ProductAttributes = Common.ObjectAttributesValues(StructureOfAnalytics.Products, "ItemsType,UseVariants");
		
		ProductTypesWithoutStorageControl = New Array;
		ProductTypesWithoutStorageControl.Add(Enums.ItemsTypes.OperationService);
		ProductTypesWithoutStorageControl.Add(Enums.ItemsTypes.Work_5);
		
		If ProductTypesWithoutStorageControl.Find(ProductAttributes.ItemsType) = Undefined Then
			
			If Not ValueIsFilled(StructureOfAnalytics.StorageLocation) Then
				Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: chỉ ra mặt hàng có kiểu khác với ""Dịch vụ"" hoặc ""Công việc"" và không điền nơi cất giữ.';
								|ru = 'Ошибка при получении набора регистра сведений %Couples1%: указана номенклатура с типом, отличным от ""Услуга"" или ""Работа"", а место хранения не заполнено.';
								|en = 'An error occurred while retrieving a set of data from information register %Couples1%: items with type other than “Service” or “Work” are found but the storage location is not specified.'; fa = 'An error occurred while retrieving a set of data from information register %Couples1%: items with type other than “Service” or “Work” are found but the storage location is not specified.';
								|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: indicato articolo con tipo diverso da ""Servizio"" o ""Lavoro"", mentre il luogo di stoccaggio non è indicato.';
								|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: podana nomenklatura z rodzajem innym niż ""Usługa"" lub ""Praca"", a miejsce przechowywania nie zostało wypełnione.';
								|tr = '%Couples1% bilgi kaydı kümesi alınırken hata oluştu: ""Hizmet"" veya ""İş"" dışında bir tipe sahip öğe belirtildi ve depolama alanı doldurulmadı.'");
				Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
				
				Raise Template1;
			EndIf;
			
		EndIf;
		
		If ProductAttributes.ItemsType = Enums.ItemsTypes.ReusablePackage Then 
			
			If ValueIsFilled(StructureOfAnalytics.Purpose)
				And Not TypeOf(StructureOfAnalytics.StorageLocation) = Type("CatalogRef.BusinessStructure") Then
				
				Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: chỉ ra mặt hàng có kiểu ""Bao bì luân chuyển"" và chỉ ra mục đích.';
								|ru = 'Ошибка при получении набора регистра сведений %Couples1%: указана номенклатура с типом ""Многооборотная тара"", и указано назначение.';
								|en = 'An error occurred while retrieving a set of data from information register %Couples1%: items with the ""Reusable packaging"" type are specified but intended use is indicated.'; fa = 'An error occurred while retrieving a set of data from information register %Couples1%: items with the ""Reusable packaging"" type are specified but intended use is indicated.';
								|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: sono indicati gli articoli del tipo ""Imballo restituibile"" ed è indicata la destinazione.';
								|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: została podana nomenklatura z rodzajem ""Opakowanie wielokrotnego użytku"", i podano przeznaczenie.';
								|tr = '%Couples1% bilgi kaydı kümesi alınırken hata oluştu: ""Yeniden kullanılabilir ambalaj"" tipinde öğe ve atama belirtildi.'");
				Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
				
				Raise Template1;
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(ProductAttributes.UseVariants)
			Or ProductAttributes.UseVariants = Enums.ItemVariantsUsageOptions.DontUse Then
			
			If ValueIsFilled(StructureOfAnalytics.Characteristic) Then
				Template1 = NStr("vi = 'Lỗi khi nhận tập hợp của biểu ghi thông tin %Couples1%: đối với mặt hàng chưa thiết lập nhập đặc tính, nhưng đã chỉ ra đặc tính.';
								|ru = 'Ошибка при получении набора регистра сведений %Couples1%: для номенклатуры не настроено ведение характеристики, но характеристика указана.';
								|en = 'An error occurred while getting the %Couples1% information register set: variants are not enabled for the item, but the variant is specified.'; fa = 'An error occurred while getting the %Couples1% information register set: variants are not enabled for the item, but the variant is specified.';
								|it = 'Ошибка при получении набора регистра сведений %Couples1%: для номенклатуры не настроено ведение характеристики, но характеристика указана.';
								|pl = 'An error occurred while getting the %Couples1% information register set: variants are not enabled for the item, but the variant is specified.';
								|tr = 'Bilgi kaydı kümesi alınırken hata %Couples1%: ürün için belirtilen varyant girişi ayarlanmadı, ancak varyant belirtildi.'");
				Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
				
				Raise Template1;
			EndIf;
			
		Else
			
			If Not ValueIsFilled(StructureOfAnalytics.Characteristic) Then
				Template1 = NStr("vi = 'Lỗi khi nhận tập hợp của biểu ghi thông tin %Couples1%: đối với mặt hàng đã thiết lập nhập đặc tính, nhưng chưa chỉ ra đặc tính.';
								|ru = 'Ошибка при получении набора регистра сведений %Couples1%: для номенклатуры настроено ведение характеристики, но характеристика не указана.';
								|en = 'An error occurred while getting the %Couples1% information register set: variants are enabled for the item, but the variant is not specified.'; fa = 'An error occurred while getting the %Couples1% information register set: variants are enabled for the item, but the variant is not specified.';
								|it = 'Ошибка при получении набора регистра сведений %Couples1%: для номенклатуры настроено ведение характеристики, но характеристика не указана.';
								|pl = 'An error occurred while getting the %Couples1% information register set: variants are enabled for the item, but the variant is not specified.';
								|tr = 'Bilgi kaydı kümesi alınırken hata %Couples1%: ürün için belirtilen varyant girişi ayarlandı, ancak varyant belirtilmedi.'");
				Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
				
				Raise Template1;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(StructureOfAnalytics.Series) Then
		
		If TypeOf(StructureOfAnalytics.StorageLocation) <> Type("CatalogRef.Warehouses")
			And TypeOf(StructureOfAnalytics.StorageLocation) <> Type("CatalogRef.CounterpartyContracts")
			And TypeOf(StructureOfAnalytics.StorageLocation) <> Type("CatalogRef.BusinessStructure") Then
			
			Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: đã chỉ ra sê-ri, nhưng nơi cất giữ không có kiểu đó.';
							|ru = 'Ошибка при получении набора регистра сведений %Couples1%: серия указана, но место хранения не того типа.';
							|en = 'An error occurred while retrieving a set of data from information register %Couples1%: batch is specified but the storage location is of a wrong type.'; fa = 'An error occurred while retrieving a set of data from information register %Couples1%: batch is specified but the storage location is of a wrong type.';
							|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: la serie è indicata, ma la posizione di stoccaggio non è del tipo appropriato.';
							|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: seria jest podana, ale miejsce przechowywania jest nie tego rodzaju.';
							|tr = '%Couples1% veri kayıt kümesi alınırken hata oluştu: parti belirtildi, ancak depolama alanı yanlış tipe sahip.'");
			Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
			
			Raise Template1;
			
		EndIf;
		
		If ProductAttributes.ItemsType <> Enums.ItemsTypes.OwnGoods Then
			Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: đã chỉ ra sê-ri, nhưng mặt hàng không có kiểu ""Hàng hóa"".';
							|ru = 'Ошибка при получении набора регистра сведений %Couples1%: серия указана, но номенклатура не с типом ""Товар"".';
							|en = 'An error occurred while retrieving a set of data from information register %Couples1% batch is specified but the item type is not ""Goods"".'; fa = 'An error occurred while retrieving a set of data from information register %Couples1% batch is specified but the item type is not ""Goods"".';
							|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: la serie è indicata ma gli articoli non hanno il tipo ""Merce"".';
							|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: seria jest podana, ale nomenklatura nie jest z rodzajem ""Towar"".';
							|tr = '%Couples1% bilgi kaydı kümesi alınırken hata oluştu: parti belirtildi, ancak öğe ""Ürünler"" tipinde değil.'");
			Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
			
			Raise Template1;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(StructureOfAnalytics.ProductCostElement) Then
		If TypeOf(StructureOfAnalytics.StorageLocation) <> Type("CatalogRef.BusinessStructure")
			And TypeOf(StructureOfAnalytics.StorageLocation) <> Type("CatalogRef.CounterpartyContracts") Then
			Template1 = NStr("vi = 'Lỗi khi nhận tập hợp biểu ghi thông tin %Couples1%: %Couples2% đã chỉ ra, nhưng nơi cất giữ không có kiểu đó.';
							|ru = 'Ошибка при получении набора регистра сведений %Couples1%: %Couples2% указана, но место хранения не того типа.';
							|en = 'An error occurred while retrieving a set of data from information register %Couples1%: %Couples2% is specified but the storage location is of a wrong type.'; fa = 'An error occurred while retrieving a set of data from information register %Couples1%: %Couples2% is specified but the storage location is of a wrong type.';
							|it = 'Errore di ricezione del pacchetto del registro dati %Couples1%: la %Couples2% è indicata, ma la posizione di stoccaggio non è del tipo appropriato.';
							|pl = 'Błąd podczas pobierania zestawu rejestru informacji %Couples1%: %Couples2% jest podana, ale miejsce przechowywania jest nie tego rodzaju.';
							|tr = '%Couples1% bilgi kaydı kümesi alınırken hata oluştu: %Couples2% belirtildi, ancak depolama alanı yanlış tipe sahip.'");
			Template1 = StrReplace(Template1, "%Couples1%", "ItemsLocationAttributes");
			Template1 = StrReplace(Template1, "%Couples2%", "ProductCostElement");
			
			Raise Template1;
		EndIf;
	EndIf;
	
	RecordSet = InformationRegisters.ItemsLocationAttributes.CreateRecordSet();
	
	For Each KeyValue In StructureOfAnalytics Do
		Filter = RecordSet.Filter[KeyValue.Key]; // FilterItem
		Filter.Set(KeyValue.Value);
	EndDo;
	
	NewRow = RecordSet.Add();
	
	FillPropertyValues(NewRow, StructureOfAnalytics);
	
	Return RecordSet;
	
EndFunction

#EndRegion

#Region PopulatingAnalyticsKeysInCollection

Function TextOfAnalyticsKeyValueInCollection(FieldsNames)
	QueryText =
	"SELECT
	|	Collection.LineNumber - 1 AS IndexOf,
	|	&AnalyticsField AS ItemsLocationAttributes,
	|	&ProductsField AS Products,
	|	&CharacteristicField AS Characteristic,
	|	&DestinationField_ AS Purpose,
	|	&CalculationArticleField AS ProductCostElement,
	|	CASE
	|		WHEN &BatchesIndicationStatus IN (14, 18)
	|			THEN &FieldSeries
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE
	|		WHEN &WarehouseGoodsField IN (
	|				VALUE(Catalog.Warehouses.EmptyRef),
	|				VALUE(Catalog.BusinessStructure.EmptyRef),
	|				VALUE(Catalog.Partners.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|				UNDEFINED)
	|			THEN &PlacesWhereGoodsAreRegistered
	|		ELSE &WarehouseGoodsField
	|	END AS WarehouseGoods,
	|	CASE
	|		WHEN &FieldWarehouseMultiTurnContainer IN (
	|				VALUE(Catalog.Warehouses.EmptyRef),
	|				VALUE(Catalog.BusinessStructure.EmptyRef),
	|				VALUE(Catalog.Partners.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|				UNDEFINED)
	|			THEN &PlacesOfAccountingMultiTurnPackaging
	|		ELSE &FieldWarehouseMultiTurnContainer
	|	END AS WarehouseMultiTurnContainers,
	|	CASE
	|		WHEN &WarehouseServiceField IN (
	|				VALUE(Catalog.Warehouses.EmptyRef),
	|				VALUE(Catalog.BusinessStructure.EmptyRef),
	|				VALUE(Catalog.Partners.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|				UNDEFINED)
	|			THEN &PlacesOfAccountingService
	|		ELSE &WarehouseServiceField
	|	END AS WarehouseService,
	|	CASE
	|		WHEN &WarehouseWorkField IN (
	|				VALUE(Catalog.Warehouses.EmptyRef),
	|				VALUE(Catalog.BusinessStructure.EmptyRef),
	|				VALUE(Catalog.Partners.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|				UNDEFINED)
	|			THEN &PlacesOfAccountingWork
	|		ELSE &WarehouseWorkField
	|	END AS WarehouseWork
	|INTO Collection
	|FROM
	|	&Collection AS Collection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Collection.IndexOf AS IndexOf,
	|	Collection.Products AS Products,
	|	Collection.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Collection.Characteristic AS Characteristic,
	|	Collection.Series AS Series,
	|	Collection.Purpose AS Purpose,
	|	Collection.ProductCostElement AS ProductCostElement,
	|	CASE CatProducts.ItemsType
	|		WHEN VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN Collection.WarehouseMultiTurnContainers
	|		WHEN VALUE(Enum.ItemsTypes.OperationService)
	|			THEN Collection.WarehouseService
	|		WHEN VALUE(Enum.ItemsTypes.Work_5)
	|			THEN Collection.WarehouseWork
	|		ELSE Collection.WarehouseGoods
	|	END AS StorageLocation
	|INTO TTCollectionWithWarehouse
	|FROM
	|	Collection AS Collection
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON (CatProducts.Ref = Collection.Products)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Collection.IndexOf AS IndexOf,
	|	Dimension.DimensionKey AS ItemsLocationAttributes,
	|	Collection.Products AS Products,
	|	Collection.Characteristic AS Characteristic,
	|	Collection.Series AS Series,
	|	Collection.Purpose AS Purpose,
	|	Collection.ProductCostElement AS ProductCostElement,
	|	Collection.StorageLocation AS StorageLocation
	|FROM
	|	TTCollectionWithWarehouse AS Collection
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON (Dimension.Products = Collection.Products)
	|			AND (Dimension.Characteristic = Collection.Characteristic)
	|			AND (Dimension.Series = Collection.Series)
	|			AND (Dimension.Purpose = Collection.Purpose)
	|			AND (Dimension.ProductCostElement = Collection.ProductCostElement)
	|			AND (Dimension.StorageLocation = Collection.StorageLocation)
	|WHERE
	|	(Dimension.DimensionKey IS NULL
	|			OR Dimension.DimensionKey <> Collection.ItemsLocationAttributes
	|			OR Dimension.DimensionKey = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Collection";
	
	// replace the substituted fields from the field name structure in the query text
	QueryText = StrReplace(QueryText, "&AnalyticsField",		"Collection." + FieldsNames.ItemsLocationAttributes);
	QueryText = StrReplace(QueryText, "&ProductsField",	"Collection." + FieldsNames.Products);
	QueryText = StrReplace(QueryText, "&CharacteristicField",	"Collection." + FieldsNames.Characteristic);
	
	// The destination field may not be present in the table.
	If ValueIsFilled(FieldsNames.Purpose) Then
		If TypeOf(FieldsNames.Purpose) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&DestinationField_", FieldsNames.Purpose.FieldText);
		Else
			QueryText = StrReplace(QueryText, "&DestinationField_", "Collection." + FieldsNames.Purpose);
		EndIf;  
	Else
		QueryText = StrReplace(QueryText, "&DestinationField_", "VALUE(Catalog.Assignments.EmptyRef)");
	EndIf; 
	// In most cases, the calculation article field is missing from the table.
	If ValueIsFilled(FieldsNames.ProductCostElement) Then
		If TypeOf(FieldsNames.ProductCostElement) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&CalculationArticleField", FieldsNames.ProductCostElement.FieldText);
		Else
			ReplacementString = """""";
			ReplacementString = "Collection." + FieldsNames.ProductCostElement;
			QueryText = StrReplace(QueryText, "&CalculationArticleField", ReplacementString);
		EndIf;  
	Else
		ReplacementString = """""";
		ReplacementString = "VALUE(Catalog.ProductCostElements.EmptyRef)";
		QueryText = StrReplace(QueryText, "&CalculationArticleField", ReplacementString);
	EndIf;
	
	// The series fields may not be specified
	SeriesAreSpecified = FieldsNames.Property("BatchesIndicationStatus") And ValueIsFilled(FieldsNames.BatchesIndicationStatus);
	QueryText = StrReplace(QueryText, "&FieldSeries", ?(SeriesAreSpecified, "Collection." + FieldsNames.Series, "UNDEFINED"));
	QueryText = StrReplace(QueryText, "&BatchesIndicationStatus", ?(SeriesAreSpecified, "Collection." + FieldsNames.BatchesIndicationStatus, "0"));
	
	// let's form the names of the warehouse receipt fields from the collection by product types
	FieldNameArbitrary = ?(ValueIsFilled(FieldsNames.Arbitrary), "Collection." + FieldsNames.Arbitrary, "UNDEFINED");
	If FieldsNames.Property("OwnGoods") Then
		If TypeOf(FieldsNames.OwnGoods) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&WarehouseGoodsField", FieldsNames.OwnGoods.FieldText);
		Else
			QueryText = StrReplace(QueryText, "&WarehouseGoodsField", NameOfAccountingLocationField(FieldsNames, "OwnGoods"));
		EndIf;
	Else
		QueryText = StrReplace(QueryText, "&WarehouseGoodsField", FieldNameArbitrary);
	EndIf;
	
	If FieldsNames.Property("ReusablePackage") Then
		If TypeOf(FieldsNames.ReusablePackage) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&FieldWarehouseMultiTurnContainer", FieldsNames.ReusablePackage.FieldText);
		Else
			QueryText = StrReplace(QueryText, "&FieldWarehouseMultiTurnContainer", NameOfAccountingLocationField(FieldsNames, "ReusablePackage"));
		EndIf;
	Else
		QueryText = StrReplace(QueryText, "&FieldWarehouseMultiTurnContainer", FieldNameArbitrary);
	EndIf;
	
	If FieldsNames.Property("OperationService") Then
		If TypeOf(FieldsNames.OperationService) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&WarehouseServiceField", FieldsNames.OperationService.FieldText);
		Else
			QueryText = StrReplace(QueryText, "&WarehouseServiceField", NameOfAccountingLocationField(FieldsNames, "OperationService"));
		EndIf;
	Else
		QueryText = StrReplace(QueryText, "&WarehouseServiceField", FieldNameArbitrary);
	EndIf;
	
	If FieldsNames.Property("Work_5") Then
		If TypeOf(FieldsNames.Work_5) = Type("Structure") Then
			QueryText = StrReplace(QueryText, "&WarehouseWorkField", FieldsNames.Work_5.FieldText);
		Else
			QueryText = StrReplace(QueryText, "&WarehouseWorkField", NameOfAccountingLocationField(FieldsNames, "Work_5"));
		EndIf;
	Else
		QueryText = StrReplace(QueryText, "&WarehouseWorkField", FieldNameArbitrary);
	EndIf;
	
	Return QueryText;
EndFunction

Function NameOfAccountingLocationField(FieldsNames, NameKey, CollectionName = "Collection")
	Return
		?(ValueIsFilled(FieldsNames[NameKey]),
			CollectionName + "." + FieldsNames[NameKey],
			"UNDEFINED");
EndFunction

#EndRegion

#EndRegion

#EndIf
